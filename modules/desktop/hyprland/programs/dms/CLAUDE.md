# DMS (desktop shell)

DankMaterialShell is pulled via the `dms` flake input (tracks the `stable` branch — don't switch to master without reason). Custom QML plugins live under `plugins/`. When writing plugin QML, avoid reserved names like `signal`, `state`, `connect` — they shadow built-ins and silently break property bindings. Use prefixed names (e.g. `signalPct`, `modemState`).

DMS writes GTK theme `.ini` + xdg portal settings but may leave gsettings stale; if GTK4 apps look wrong after a theme change, check `gsettings get org.gnome.desktop.interface icon-theme`.
