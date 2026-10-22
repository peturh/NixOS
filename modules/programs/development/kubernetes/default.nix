{pkgs, ...}: let
  docker = "${pkgs.docker}/bin/docker";

  # Stop/start every kind node container (kind labels them with their
  # cluster name). `stop` records which nodes were running in a state file so
  # `start` brings back exactly those.
  #
  # Stops are short and end in SIGKILL on purpose: inside the node,
  # kube-apiserver sits in graceful termination for well over a minute once
  # etcd is gone, so a "graceful" stop never finishes in useful time. etcd is
  # crash-safe and kind recovers from a killed node on the next start.
  kindPower = pkgs.writeShellScript "kind-power" ''
    state=$2
    case $1 in
      stop)
        nodes=$(${docker} ps --filter label=io.x-k8s.kind.cluster --format '{{.Names}}')
        [ -n "$nodes" ] || exit 0
        echo "$nodes" > "$state"
        ${docker} stop -t "$3" $nodes || ${docker} kill $nodes || true
        ;;
      start)
        [ -s "$state" ] || exit 0
        ${docker} start $(${pkgs.coreutils}/bin/cat "$state") || true
        rm -f "$state"
        ;;
    esac
  '';
in {
  environment.systemPackages = with pkgs; [
    kubectl
    kind
  ];

  # stateVersion 23.11 defaults this to true: dockerd then exits at shutdown
  # leaving every container running, and their docker-*.scope units have no
  # shutdown ordering, so the kind node (its own systemd, containerd, etcd,
  # apiserver, pods) lived until systemd-shutdown's final kill pass and hung
  # poweroff there. Without it dockerd stops all containers while filesystems
  # are still up. kind-shutdown below handles kind before dockerd gets to it.
  virtualisation.docker.liveRestore = false;

  # Stop kind nodes before docker on poweroff/reboot, and start them again
  # on the next boot (a stopped container is skipped by docker's restart
  # policy, so docker alone wouldn't).
  systemd.services.kind-shutdown = {
    description = "Stop kind clusters before docker on shutdown";
    wants = ["docker.service"];
    after = ["docker.service"];
    wantedBy = ["multi-user.target"];
    # a restart on rebuild would kill and restart the running cluster
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "kind-power";
      TimeoutStartSec = 60;
      TimeoutStopSec = 30;
      ExecStart = "${kindPower} start /var/lib/kind-power/nodes";
      ExecStop = "${kindPower} stop /var/lib/kind-power/nodes 10";
    };
  };

  # Kill kind nodes before suspend/hibernate and start them on resume, so a
  # cluster isn't frozen mid-flight and doesn't wake up to expired leases.
  systemd.services.kind-sleep = {
    description = "Stop kind clusters around sleep";
    before = ["sleep.target"];
    wantedBy = ["sleep.target"];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
      TimeoutStopSec = 60;
      ExecStart = "${kindPower} stop /run/kind-sleep-nodes 0";
      # StopWhenUnneeded also fires on shutdown; don't restart the cluster then.
      ExecStop = pkgs.writeShellScript "kind-resume" ''
        [ "$(${pkgs.systemd}/bin/systemctl is-system-running)" = "stopping" ] && exit 0
        exec ${kindPower} start /run/kind-sleep-nodes
      '';
    };
  };
}
