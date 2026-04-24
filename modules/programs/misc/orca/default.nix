{
  pkgs,
  lib,
  ...
}: let
  # ---- Piper voice models ---------------------------------------------------
  # Voice files live on Hugging Face. We fetch the .onnx and matching
  # .onnx.json declaratively, then assemble them into a single directory so
  # piper can find the JSON next to the model.
  amyOnnx = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx";
    hash = "sha256-s6bke1e4x/vmoM4lGBYaUPWanN2KUINcAssCvdYgbBg=";
  };

  amyOnnxJson = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json";
    hash = "sha256-laI+tNQpCdON9zu5rH9F9Zfb/N4tG/lSb96vVGaXfXc=";
  };

  piperVoices = pkgs.runCommand "piper-voices" {} ''
    mkdir -p $out
    cp ${amyOnnx}      $out/en_US-amy-medium.onnx
    cp ${amyOnnxJson}  $out/en_US-amy-medium.onnx.json
  '';

  # ---- piper -> paplay wrapper --------------------------------------------
  # speech-dispatcher runs GenericExecuteSynth via `sh -c 'set -o pipefail; …'`.
  # If piper or paplay returns non-zero (which happens easily: Orca cancels a
  # message mid-flight by SIGTERMing the pipeline, paplay races PulseAudio at
  # session start, the model file is briefly busy, …), `pipefail` propagates
  # that to sd_generic. After enough such failures speech-dispatcher decides
  # the module crashed and never tries it again — every subsequent request
  # silently falls back to espeak-ng for the rest of the session, which is
  # exactly the "Orca doesn't always use Amy" symptom.
  #
  # The wrapper synthesises into a temp .raw file first, then plays it. That
  # decouples piper from paplay (no broken-pipe cascade on cancel) and lets us
  # always exit 0 so sd_generic stays healthy.
  piperBin = lib.getExe pkgs.piper-tts;
  paplayBin = "${pkgs.pulseaudio}/bin/paplay";

  piperSpeak = pkgs.writeShellApplication {
    name = "piper-speak";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      # Args: $1 = voice name (e.g. en_US-amy-medium), text on stdin.
      set -u
      voice="''${1:-en_US-amy-medium}"
      model="${piperVoices}/$voice.onnx"
      if [ ! -f "$model" ]; then
        model="${piperVoices}/en_US-amy-medium.onnx"
      fi

      tmp="$(mktemp --tmpdir piper-speak.XXXXXX.raw)"
      trap 'rm -f "$tmp"' EXIT

      # Synthesize. Failure is non-fatal so sd_generic stays alive.
      if ! ${piperBin} -m "$model" --output-raw >"$tmp" 2>/dev/null; then
        exit 0
      fi

      [ -s "$tmp" ] || exit 0

      ${paplayBin} --raw --rate=22050 --format=s16le --channels=1 "$tmp" \
        >/dev/null 2>&1 || true

      exit 0
    '';
  };

  piperSpeakBin = lib.getExe piperSpeak;

  # ---- speech-dispatcher integration --------------------------------------
  piperModuleConf = ''
    # Auto-generated piper module for speech-dispatcher.
    # The wrapper script handles its own error suppression; we still ship
    # Debug 0 because Debug 1 fills /run with megabytes per minute.
    Debug 0

    GenericExecuteSynth \
    "printf %s \'$DATA\' | ${piperSpeakBin} \'$VOICE\'"

    GenericCmdDependency "${piperSpeakBin}"

    # Empty values are valid here (mimic3-generic.conf does the same) but the
    # dotconf parser warns about them; using a single space silences the
    # warning without changing behaviour.
    GenericPunctNone " "
    GenericPunctSome " "
    GenericPunctMost " "
    GenericPunctAll  " "

    # Map every English variant Orca might request to Amy. Without these,
    # requests for e.g. en-GB fall through to espeak-ng.
    AddVoice "en"    "FEMALE1" "en_US-amy-medium"
    AddVoice "en-US" "FEMALE1" "en_US-amy-medium"
    AddVoice "en-GB" "FEMALE1" "en_US-amy-medium"
    AddVoice "en"    "MALE1"   "en_US-amy-medium"
    AddVoice "en-US" "MALE1"   "en_US-amy-medium"
    AddVoice "en-GB" "MALE1"   "en_US-amy-medium"

    DefaultVoice "en_US-amy-medium"
  '';

  # We override speechd.conf to make piper the default. We also re-register
  # espeak-ng so it's still available as a fallback (Orca can switch via
  # `orca -s` -> Voice). When services.speechd.config is set, NixOS stops
  # symlinking the package's default modules dir, so we have to provide the
  # espeak-ng module config explicitly.
  espeakNgConf = builtins.readFile "${pkgs.speechd}/etc/speech-dispatcher/modules/espeak-ng.conf";

  speechdConf = ''
    LanguageDefaultModule "en"    "piper"
    LanguageDefaultModule "en-US" "piper"
    LanguageDefaultModule "en-GB" "piper"

    AddModule "piper"     "sd_generic"   "piper.conf"
    AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"

    DefaultModule        piper
    DefaultLanguage      en-US
    DefaultVoiceType     FEMALE1

    DefaultRate          0
    DefaultPitch         0
    DefaultVolume        100
    DefaultPunctuationMode none
    DefaultSpelling      off

    AudioOutputMethod    pulse
    LogLevel             3
    LogDir               "default"
  '';
in {
  # AT-SPI accessibility bus is required for Orca to read GTK/Qt/Chromium UIs.
  # Hyprland (non-GNOME) does not enable it implicitly.
  services.gnome.at-spi2-core.enable = true;

  services.speechd = {
    enable = true;
    config = speechdConf;
    modules = {
      piper = piperModuleConf;
      "espeak-ng" = espeakNgConf;
    };
  };

  # QT_ACCESSIBILITY makes Qt apps expose their accessibility tree to AT-SPI.
  # GTK apps do this automatically when the bus is running.
  environment.sessionVariables = {
    QT_ACCESSIBILITY = "1";
  };

  environment.systemPackages = with pkgs; [
    orca
    speechd
    espeak-ng
    piper-tts
    piperSpeak
  ];

  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        orca
      ];
    })
  ];
}
