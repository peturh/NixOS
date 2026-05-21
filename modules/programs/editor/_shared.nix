{pkgs}: rec {
  extensions =
    (with pkgs.vscode-extensions; [
      bbenoist.nix
      eamodio.gitlens
      yzhang.markdown-all-in-one
      tamasfe.even-better-toml
      rust-lang.rust-analyzer
    ])
    ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # QML syntax highlighting (not packaged in nixpkgs).
      {
        name = "QML";
        publisher = "bbenoist";
        version = "1.0.0";
        sha256 = "sha256-tphnVlD5LA6Au+WDrLZkAxnMJeTCd3UTyTN1Jelditk=";
      }
    ];

  keybindings = [
    {
      key = "ctrl+q";
      command = "editor.action.commentLine";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "ctrl+s";
      command = "workbench.action.files.saveFiles";
    }
  ];

  userSettings = {
    "update.mode" = "none";
    # "extensions.autoUpdate" = false; # Fixes vscode freaking out when theres an update
    "window.titleBarStyle" = "custom"; # needed otherwise vscode crashes, see https://github.com/NixOS/nixpkgs/issues/246509
    "window.menuBarVisibility" = "classic";
    "window.zoomLevel" = 0.5;
    "window.autoDetectColorScheme" = true;
    "workbench.preferredDarkColorTheme" = "Dark Modern";
    "workbench.preferredLightColorTheme" = "Default Light Modern";
    "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'SymbolsNerdFont', 'monospace', monospace";
    "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'SymbolsNerdFont'";
    "editor.fontSize" = 14;
    "explorer.confirmDragAndDrop" = false;
    "editor.fontLigatures" = true;
    "workbench.startupEditor" = "none";
    "telemetry.enableCrashReporter" = false;
    "telemetry.enableTelemetry" = false;

    "security.workspace.trust.untrustedFiles" = "open";

    "git.enableSmartCommit" = true;
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "gitlens.hovers.annotations.changes" = false;
    "gitlens.hovers.avatars" = false;

    "editor.semanticHighlighting.enabled" = true;
    "gopls" = {"ui.semanticTokens" = true;};

    "editor.codeActionsOnSave" = {"source.organizeImports" = "explicit";};
    "editor.inlineSuggest.enabled" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;

    "editor.minimap.enabled" = false;
    "workbench.sideBar.location" = "left";
    "workbench.layoutControl.type" = "menu";
    "workbench.editor.limit.enabled" = true;
    "workbench.editor.limit.value" = 10;
    "workbench.editor.limit.perEditorGroup" = true;
    "explorer.openEditors.visible" = 0;
    "breadcrumbs.enabled" = true;
    "editor.renderControlCharacters" = false;
    "editor.stickyScroll.enabled" = false; # Top code preview
    "editor.scrollbar.verticalScrollbarSize" = 2;
    "editor.scrollbar.horizontalScrollbarSize" = 2;
    "editor.scrollbar.vertical" = "hidden";
    "editor.scrollbar.horizontal" = "hidden";
    "workbench.layoutControl.enabled" = false;

    "editor.mouseWheelZoom" = true;

    "C_Cpp.autocompleteAddParentheses" = true;
    "C_Cpp.formatting" = "vcFormat";
    "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyFunction" = true;
    "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyType" = true;
    "C_Cpp.vcFormat.space.beforeEmptySquareBrackets" = true;
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.block" = "sameLine";
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.function" = "sameLine";
    "C_Cpp.vcFormat.newLine.beforeElse" = false;
    "C_Cpp.vcFormat.newLine.beforeCatch" = false;
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.type" = "sameLine";
    "C_Cpp.vcFormat.space.betweenEmptyBraces" = true;
    "C_Cpp.vcFormat.space.betweenEmptyLambdaBrackets" = true;
    "C_Cpp.vcFormat.indent.caseLabels" = true;
    "C_Cpp.intelliSenseCacheSize" = 2048;
    "C_Cpp.intelliSenseMemoryLimit" = 2048;
    "C_Cpp.default.browse.path" = [
      ''''${workspaceFolder}/**''
    ];
    "C_Cpp.default.cStandard" = "gnu11";
    "C_Cpp.inlayHints.parameterNames.hideLeadingUnderscores" = false;
    "C_Cpp.intelliSenseUpdateDelay" = 500;
    "C_Cpp.workspaceParsingPriority" = "medium";
    "C_Cpp.clang_format_sortIncludes" = true;
    "C_Cpp.doxygen.generatedStyle" = "/**";
  };
}
