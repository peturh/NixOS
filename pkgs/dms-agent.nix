{
  inputs,
  runCommand,
}:
runCommand "dms-agent-plugin-0.3.0" {} ''
  mkdir -p $out/share/DankMaterialShell/plugins/dmsAgent
  cp -r ${inputs.dms-agent}/. $out/share/DankMaterialShell/plugins/dmsAgent/
''
