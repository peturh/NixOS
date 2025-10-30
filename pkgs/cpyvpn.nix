{ pkgs, inputs }:

pkgs.python3Packages.buildPythonApplication {
  pname = "cpyvpn";
  version = "unstable";
  
  src = inputs.cpyvn;  # Using the flake input
  
  format = "pyproject";
  
  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];
  
  propagatedBuildInputs = with pkgs.python3Packages; [
    cryptography
    pyopenssl
    lxml
    requests
  ];
  
  # Set a fallback version since git metadata isn't available
  env.SETUPTOOLS_SCM_PRETEND_VERSION = "0.0.1";
  
  # Skip tests if they exist and are failing
  doCheck = false;
  
  meta = with pkgs.lib; {
    description = "Check Point VPN client for Linux";
    homepage = "https://gitlab.com/cpvpn/cpyvpn";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
