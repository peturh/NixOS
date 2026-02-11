{
  inputs,
  outputs,
  pkgs,
  username,
  browser,
  terminal,
  locale,
  timezone,
  kbdLayout,
  kbdVariant,
  consoleKeymap,
  self,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-index-database.nixosModules.nix-index
  ];

  programs.nix-index-database.comma.enable = true;

  # Configure sops-nix for secrets management
  sops = {
    defaultSopsFile = ../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/${username}/NixOS/age.key";
    
    secrets = {
      "vpn-server" = {
        key = "server";
        owner = username;
      };
      "vpn-realm" = {
        key = "realm";
        owner = username;
      };
      "vpn-username" = {
        key = "username";
        owner = username;
      };
      "vpn-password" = {
        key = "password";
        owner = username;
      };
      "jira-username" = {
        key = "jira_username";
        owner = username;
      };
      "jira-password" = {
        key = "jira_password";
        owner = username;
      };
      "devops-username" = {
        key = "devops_username";
        owner = username;
      };
      "devops-password" = {
        key = "devops_password";
        owner = username;
      };
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      "input"
      "disk"
      "libvirtd"
      "video"
      "audio"
      "power"
      "plugdev"
    ];
  };

  # Create plugdev group for USB device access
  users.groups.plugdev = {};

  # Common home-manager options that are shared between all systems.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${username} = {pkgs, ...}: {
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      xdg.enable = true;
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-hyprland xdg-desktop-portal-gtk ];
        xdgOpenUsePortal = true;
      };
      home.username = username;
      home.homeDirectory =
        if pkgs.stdenv.isDarwin
        then "/Users/${username}"
        else "/home/${username}";
      home.stateVersion = "23.11"; # Please read the comment before changing.
      home.sessionVariables = {
        EDITOR = "micro";
        BROWSER = browser;
        TERMINAL = terminal;
      };

      # Packages that don't require configuration. If you're looking to configure a program see the /modules dir
      home.packages = with pkgs; [
        # Applications
        remmina  # VNC/RDP/SSH remote desktop client

        # Terminal
        file
        fzf
        fd
        git
        gh
        htop
        libjxl
        microfetch
        neofetch
        nix-prefetch-scripts
        ripgrep
        tldr
        unzip
      ];
    };
  };

  zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 50; # Use 50% of RAM for compressed swap
  };

  nix.settings = {
  # ... your existing settings ...
  max-jobs = "auto"; # Use all available cores
  cores = 0; # Use all cores per build job (0 = auto)
  
  # Reduce memory usage during builds
  builders-use-substitutes = true;
  
  # Enable parallel downloads
  http-connections = 0; # 0 = unlimited (default is 25)
  max-substitution-jobs = 16; # Parallel downloads from binary caches
};

  # Filesystems support
  boot.supportedFilesystems = ["ntfs" "exfat" "ext4" "fat32" "btrfs"];
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_lavd"; # https://github.com/sched-ext/scx/blob/main/scheds/rust/README.md
  };

  # Bootloader.
  boot = {
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_zen; # _latest, _zen, _xanmod_latest, _hardened, _rt, _OTHER_CHANNEL, etc.
    kernelParams = [
      "amd_pmc.enable_stb=1"  # Enable System Trace Buffer for better AMD s2idle suspend/resume
    ];
    
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = null; # Display bootloader indefinitely until user selects OS
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        gfxmodeEfi = "2715x1527"; # for 4k: 3840x2160
        gfxmodeBios = "2715x1527"; # for 4k: 3840x2160
        theme = pkgs.stdenv.mkDerivation {
          pname = "distro-grub-themes";
          version = "3.1";
          src = pkgs.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "v3.1";
            hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
          };
          installPhase = "cp -r customize/nixos $out";
        };
      };
    };
  };

  # Timezone and locale
  time.timeZone = timezone;
  i18n.defaultLocale = locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
  };
  console.keyMap = consoleKeymap; # Configure console keymap
  services.xserver = {
    exportConfiguration = true; # Make sure /etc/X11/xkb is populated so localectl works correctly
    xkb = {
      layout = kbdLayout;
      variant = kbdVariant;
    };
  };

  security = {
    polkit.enable = true;
    #sudo.wheelNeedsPassword = false;
  };

  # Enable dconf for home-manager
  programs.dconf.enable = true;

  # Enable bluetooth
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # Enable Logitech wireless device support
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Enable networking
  networking = {
    # hostName = hostname; # Define your hostname.
    networkmanager.enable = true;
    # wireless.enable = true; # Enables wireless support via wpa_supplicant.
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  };

  # Enable sddm login manager
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      enableHidpi = true;
      package = pkgs.kdePackages.sddm;
      theme = "sddm-astronaut-theme";
      settings.Theme.CursorTheme = "Bibata-Modern-Classic";
      extraPackages = with pkgs; [
        kdePackages.qtmultimedia
        kdePackages.qtsvg
        kdePackages.qtvirtualkeyboard
      ];
    };
  };

  # Setup keyring
  services.gnome.gnome-keyring.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable fwupd for firmware updates
  services.fwupd.enable = true;

  # udev rules for 8BitDo controllers (firmware updates)
  services.udev.extraRules = ''
    # 8BitDo controllers - normal mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", MODE="0666", GROUP="plugdev"
    # 8BitDo controllers - bootloader mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    # Allow fwupd access
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", TAG+="uaccess"
  '';


  services.xserver.enable = true; # Enable the X11 windowing system.

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  fonts.packages = with pkgs.nerd-fonts; [
    jetbrains-mono
    fira-code
    open-dyslexic
  ];

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      # allowUnfreePredicate = _: true;
    };
  };

  environment.sessionVariables = {
    # These are the defaults, and xdg.enable does set them, but due to load
    # order, they're not set before environment.variables are set, which could
    # cause race conditions.
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_BIN_HOME = "$HOME/.local/bin";
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    sddm-astronaut # Overlayed
    pkgs.kdePackages.qtsvg
    pkgs.kdePackages.qtmultimedia
    pkgs.kdePackages.qtvirtualkeyboard
    solaar  # Logitech wireless device manager
    sops  # For managing encrypted secrets
    age   # Age encryption tool for sops
    extract-xiso  # Xbox ISO creation/extraction utility
    gnome-firmware  # GTK frontend for fwupd firmware updates
    pkgs."8bitdo-updater"  # 8BitDo gamepad firmware updater
    iptvnator  # IPTV player with Xtream Codes support (overlayed)
    makerom  # CLI tool to create Nintendo 3DS CXI/CFA/CCI/CIA files (overlayed)
    ctrtool  # CLI tool to read/extract Nintendo 3DS files (overlayed)
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  /*
     services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };
  */

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  programs = {
    nh = {
      enable = true;
      # Automatic garbage collection
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 3";
      };
      flake = "/home/${username}/NixOS";
    };
  };
  nix = {
    # Nix Package Manager Settings
    settings = {
      auto-optimise-store = true; # May make rebuilds longer but less size
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org/"
        "https://chaotic-nyx.cachix.org/"
        "https://cachix.cachix.org"
        "https://nix-gaming.cachix.org/"
        "https://hyprland.cachix.org"
        # "https://nixpkgs-wayland.cachix.org"
        # "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        # "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
      experimental-features = ["nix-command" "flakes"];
      use-xdg-base-directories = false;
      warn-dirty = false;
      keep-outputs = true;
      keep-derivations = true;
    };
    optimise.automatic = true;
    package = pkgs.nixVersions.latest;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
