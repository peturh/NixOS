<h1 align="center">
   <br>
      Péturs NixOS System
</h1>

# Installation
> [!Note]
> <p>You should review the configuration variables in `flake.nix` before installing.<br>
> Also, check the imports at the top of `hosts/Default/configuration.nix`</p>
You can use the `install.sh` script while booted into a system or in the live installer.<br>
If you prefer the latter, you can obtain an ISO from [here](https://nixos.org/download/#nixos-iso).<br>
The minimal ISO is recommended, but you can use any.
```bash
git clone https://github.com/peturh/NixOS.git ~/NixOS
```
```bash
cd ~/NixOS
```
```bash
./install.sh
```

# Rebuilding
There are 4 ways to rebuild.<br>
1) Press **Super + U**.
2) Run `rebuild` in the terminal
3) Execute the `install.sh` script again.
4) Run `sudo nixos-rebuild switch --flake ~/NixOS#Default` if you installed from the live iso then use /etc/nixos#Default 

For a list of keybinds press **Super + ?** or **Super + Ctrl + K**

<details>
<summary>How to Use the Development Shells</summary>

- To initialise a new project from a template:
```bash
nix flake init -t ~/NixOS#NAME
```
- Alternatively, use the `new` keyword to create a new directory:
```bash
nix flake new -t ~/NixOS#NAME PROJECT_NAME
```
Replace `NAME` with any template defined in `dev-shells/default.nix`.<br>
These commands will generate a flake.nix and flake.lock file in your project directory.<br>
To enter the development shell:
- Use direnv if configured, or navigate to the project directory and run:
```bash
nix develop
```
</details> 

<!-- </details> -->
<!-- <summary>Credits/Inspiration</summary> -->

### Credits/Inspiration
This config started out from [Sly-Harvey's NixOS config](https://github.com/Sly-Harvey/NixOS). Thank you, Sly Harvey!

| Credit                                                        | Reason                                 |
| ------------------------------------------------------------- | -------------------------------------- |
| [Sly Harvey](https://github.com/Sly-Harvey/NixOS)             | The original config this grew out of   |
| [Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)    | Script templates                       |
| [HyDE](https://github.com/HyDE-Project/HyDE)                  | Some more useful scripts               |
| [Vimjoyer](https://www.youtube.com/@vimjoyer)                 | Short, simple, concise guides and info |

