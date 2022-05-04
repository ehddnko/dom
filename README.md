# Docker/Docker-compose On Multipass

Using [canonical/multipass](https://github.com/canonical/multipass) to run docker/docker-compose on Windows/MacOS instead of Docker Desktop.
This project use Hyperkit/Hyper-V as a virtualization provider. **Do note that install multipass with Hyperkit/Hyper-V.**
   
## Pre-required

- git bash (Only Windows)
   * Because of running scripts in the Shell, it must set **end of line sequence** to LF.
   * Set **end of line sequence** 
      - use command `git config --global core.autocrlf false` or set '**Checkout as-is, commit as-is**' when install git.
   * Disable linux subsystem. 
      - **Setting** > **Apps** > **Apps & Feature** > **Programs & Features** > **Windows features** > disable Windows Subsystem for Linux > reboot
- multipass
   * Install on Windows: <https://multipass.run/docs/installing-on-windows>
   * Install on MacOS: <https://multipass.run/docs/installing-on-macos>
   
- pre-generated SSH key

   
## Usage

1. Configure *git-bash* on *Windows Terminal* (Only Windows)
   * Install *Windows Terminal* from microsoft store.
   * **Setting** > **Open Json File** > Edit Json
      ```json
      {
         ...
         "defaultProfile": "{124fc1da-dadc-4276-9c4e-f0524ba57a49}",
         "profiles": 
         {
            
            "defaults": {},
            "list": 
            [
               ...
               {
                  "commandline": "\"%PROGRAMFILES%\\git\\usr\\bin\\bash.exe\" -i -l",
                  "cursorShape": "filledBox",
                  "guid": "{124fc1da-dadc-4276-9c4e-f0524ba57a49}",
                  "hidden": false,
                  "icon": "%PROGRAMFILES%\\git\\mingw64\\share\\git\\git-for-windows.ico",
                  "name": "Git Bash",
                  "startingDirectory": "%USERPROFILE%"
               },
               ...
            ]
         },
         ...
      }
      ```
   
2. Remove the network sharing from the default switch and reboot. (Only Windows)
   * Run below commands from *PowerShell*.
   ```
   PS> Get-HNSNetwork | ? Name -Like "Default Switch" | Remove-HNSNetwork
   PS> Restart-Computer
   ```
   
3. Edit `cloud-config.yaml`.
   * copy content of SSH key into `cloud-config.yaml`. **Do note that save `cloud-config.yaml` as 'LF' after edit.**
   ```
   ...
   # Send pre-generated SSH private keys to the server
   # If these are present, they will be written to /etc/ssh and
   # new random keys will not be generated.
   # This keys will used inside instance.
   ssh_keys:
     # <pre-generated SSH private key>
     rsa_private: |
     -----BEGIN RSA PRIVATE KEY-----
     ...
     -----END RSA PRIVATE KEY-----

     # <pre-generated SSH public key>
     rsa_public: ssh-rsa ... user1@gmail.com

   # Add each entry to ~/.ssh/authorized_keys for the configured user or the
   # first user defined in the user definition directive.
   # This authorized keys will used between host OS and multipass instance.
   ssh_authorized_keys:
   #- <SSH public key from host machine>
     - ssh-rsa ... user1@gmail.com
   ```
   
4. Run `mkvm-zsh.sh` or `mkvm-bash.sh` script.
   * On Windows, execute *Windows Terminal* as administrator and open *git bash*. Then, run `mkvm-bash.sh` from *git bash*. 
      ```
      Usage: mkvm-bash.sh [-n | --name] [-c | --cpu] [-m | memory]
      [-d | --disk] [-v | --version] [-i | --identity] [-h | --help]

      -n, --name
          Name of Ubuntu instance.

      -c, --cpu
          Number of CPUs to allocate.
          Minimum: 1, default: 1.

      -m, --memory
          Amount of memory to allocate. Positive integers, in bytes, or with K, M, G suffix.
          Minimum: 128M, default: 1G.

      -d, --disk
          Disk space to allocate. Positive integers, in bytes, or with K, M, G siffix.
          Minimum: 512M, default: 5G.

      -v, --version
          Ubuntu image to launch an instance from. This can be a partial image hash or an Ubuntu release version, codename or alias.
          Use 'multipass find' to see what images are available.

      -i, --identity
          A file from which the identity key(private key) for public key authentication is read.

      -h, --help
          Output a usage guide and exit successfully.
      ```
      - For example: `mkvm-bash.sh -n docker-runner -c 1 -m 4G -d 64G -v 20.04 -i ~/.ssh/id_rsa`
   * On MacOS, run `mkvm-zsh.sh`.
      ```
      Usage: mkvm-zsh.sh [-n | --name] [-c | --cpu] [-m | memory]
      [-d | --disk] [-v | --version] [-i | --identity] [-h | --help]

      -n, --name
          Name of Ubuntu instance.

      -c, --cpu
          Number of CPUs to allocate.
          Minimum: 1, default: 1.

      -m, --memory
          Amount of memory to allocate. Positive integers, in bytes, or with K, M, G suffix.
          Minimum: 128M, default: 1G.

      -d, --disk
          Disk space to allocate. Positive integers, in bytes, or with K, M, G siffix.
          Minimum: 512M, default: 5G.

      -v, --version
          Ubuntu image to launch an instance from. This can be a partial image hash or an Ubuntu release version, codename or alias.
          Use 'multipass find' to see what images are available.

      -i, --identity
          A file from which the identity key(private key) for public key authentication is read.

      -h, --help
          Output a usage guide and exit successfully.
      ```
      * For example: `mkvm-zsh.sh -n docker-runner -c 1 -m 4G -d 64G -v 20.04 -i ~/.ssh/id_rsa`
   
5. Now you can access multipass instance via SSH.

   
## Delete instance

1. Run `rmvm-zsh.sh` or `rmvm-bash.sh` script.
   * On Windows, run `rmvm-bash.sh` from *git bash*.
      ```
      Usage: rmvm-bash.sh [ubuntu instance name]
      ```
      - For example: `rmvm-zsh.sh docker-runner`
   * On MacOS, run `rmvm-bash.sh`.
      ```
      Usage: rmvm-zsh.sh [ubuntu instance name]
      ```
      - For example: `rmvm-zsh.sh docker-runner`
   
2. Delete instance's SSH config
   * `vi path/to/ssh/config` > delete instance's SSH config

   
## Connect with vscode

1. Add SSH config for vscode. (Only Windows)
   * It need to add a colon to identity file path. For example:
      ```
      ...
      Host docker-runner-vscode
        HostName 192.168.64.2
        User ubuntu
        IdentityFile /c:/Users/ubuntu/.ssh/id_rsa
        IdentitiesOnly yes
      ```
   * The vscode only refer file path included colon and bash shell(e.g *git-bash*) only refer file path without colon.
     This maybe occurred by vscode extension *Remote - SSH* using cmd default on Windows. It will dive deeply to fix this later.
   * **Do note that identity file path without colon already added to SSH config by script.**
   
2. Install vscode extension *Remote - SSH*.
   
3. Edit vscode setting.
   * **Preferences** > **Settings**
      - Search **Encoding**
      - Set **Files: Encoding** to 'UTF-8'
   * Edit in `settings.json` (For Windows)
   ```json
   {
      "terminal.integrated.profiles.windows": {
         "PowerShell": {
            "source": "PowerShell",
            "icon": "terminal-powershell",
            "args": [
               "-NoExit",
               "-Command ",
               "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8"
            ]
         },
         "Command Prompt": {
            "path": [
               "${env:windir}\\Sysnative\\cmd.exe",
               "${env:windir}\\System32\\cmd.exe"
            ],
            "args": [],
            "icon": "terminal-cmd"
         },
         "GitBash": {
            "path": "C:\\Program Files\\Git\\bin\\bash.exe",
            "icon": "terminal-bash"
         }
      },
      "terminal.integrated.defaultProfile.windows": "Command Prompt",
      "remote.SSH.defaultExtensions": [
         "RoscoP.ActiveFileInStatusBar",
         "oderwat.indent-rainbow",
         "SirTori.indenticator",
         "christian-kohler.path-intellisense",
         "xaver.clang-format",
         "streetsidesoftware.code-spell-checker",
         "naumovs.color-highlight",
         "mde.select-highlight-minimap",
         "ZainChen.json",
         "eriklynd.json-tools",
         "ms-azuretools.vscode-docker",
         "formulahendry.docker-explorer",
         "mhutchie.git-graph",
         "donjayamanne.githistory",
         "eamodio.gitlens"
      ],
      "remote.SSH.foldersSortOrder": "alphabetical",
      "remote.SSH.connectTimeout": 60,
      "workbench.startupEditor": "none"
   }
   ```
   * Edit in `settings.json` (For MacOS)
   ```json
   {
      "terminal.external.osxExec": "iTerm.app",
      "terminal.integrated.fontFamily": "MesloLGS NF",
      "remote.SSH.foldersSortOrder": "alphabetical",
      "remote.SSH.connectTimeout": 60,
      "remote.SSH.defaultExtensions": [
         "RoscoP.ActiveFileInStatusBar",
         "oderwat.indent-rainbow",
         "SirTori.indenticator",
         "christian-kohler.path-intellisense",
         "xaver.clang-format",
         "streetsidesoftware.code-spell-checker",
         "naumovs.color-highlight",
         "mde.select-highlight-minimap",
         "ZainChen.json",
         "eriklynd.json-tools",
         "mhutchie.git-graph",
         "donjayamanne.githistory",
         "eamodio.gitlens",
         "ms-azuretools.vscode-docker",
         "formulahendry.docker-explorer"
      ]
   }
   ```
   
4. Run **Remote-SSH: Connect to Host...** from vscode command palette.
   * For Windows, select SSH config with colon. (manually added in previous step)
   * For MacOS, select SSH config added by script.


## Multipass Usage

- Ubuntu instance list.
   ```
   multipass ls
   ```
   
- Start Ubuntu instance.
   ```
   multipass start <instance name>
   ```
   
- Stop Ubuntu instance
   ```
   multipass stop <instance name>
   ```


## Tested environment

- On Windows 10 Pro (update version: 20H2)
   * multipass 1.8.0+win
   * multipassd 1.8.0+win
   
- On MacOS Monterey
   * multipass 1.8.1+mac
   * multipassd 1.8.1+mac


## TROBLESHOOTING

- if existing multipass instance is not shown
   * check multipassd is running by executing command "multipass --version"
   * check Hyper-V manager that instance is exist.
   * more reference : [github issues](https://github.com/canonical/multipass/issues/1119) - comment : markl11 commented on 9 Oct 2019
   * after following instruction above, please restart your pc.

- if your multipass instance is not accessible with ssh
   * check ip address of your multipass instance by executing command "multipass ls"
   * if ip address is changed, change your ip address at the HostName from ssh config file.   
      For example, config file is existing at the "/c/Users/.ssh/config"
      ```
      ...
      Host docker-runner
         HostName 192.168.145.125
         User ubuntu
         IdentityFile /c/Users/youngin.kim/.ssh/id_rsa
         IdentitiesOnly yes

      Host docker-runner-vscode
         HostName 192.168.145.125
         User ubuntu
         IdentityFile /c:/Users/youngin.kim/.ssh/id_rsa
         IdentitiesOnly yes
      ...
      ```


## References

- [Multipass Documentation](https://multipass.run/docs)
- [Multipass Github](https://github.com/canonical/multipass)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/topics/modules.html)
- [Cloud-init Github](https://github.com/canonical/cloud-init)
- [Docker Installation](https://docs.docker.com/engine/install/ubuntu/)
- [Docker-compose Installation](https://docs.docker.com/compose/install/)
- [Replacing Docker Desktop with Multipass, to avoid Docker Desktop fees](https://itnext.io/replacing-docker-desktop-with-multipass-to-avoid-docker-desktop-fees-8cbe57b9037f)
- [Using Multipass with cloud-init](https://medium.com/@ahmadb/using-multipass-with-cloud-init-bc4b92ad27d9)

   
## TODO

- Refer [cloud-init usage with Multipass](https://www.cnbeining.com/2021/09/using-docker-and-docker-compose-on-macos-with-multipass/) to setup docker/docker-compose with cloud-init.

- Add vscode devcontainer creatation.
