How to setup a whole development system from scratch in the minimum time:

Use VSCode (may want insiders as it has the command "Terminal: Move Terminal into New Window") with "Remote - SSH" extension. Use "Remote-SSH: Open SSH Configuration File..." to add the server and connect to it. Use `passwd` to update the password.

Use the boilerplate script to setup just the SSH key, and you may want to edit the email of the ` ~/.ssh/*.pub` file.

Then for Github, you go to your profile icon > Settings > SSH and GPG keys, then add the SSH key.

Use determinant systems installer to install nix:
`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`

In some cases you may need to run `PATH="$PATH:~/.nix-profile/bin:/nix/var/nix/profiles/default/bin"`, but after full setup `nix` and all the binaries like `atuin` should be working automatically.

Relogin

Run the boilerplate script again

Relogin

In order to edit things after this, edit this repo so that it is version controlled, and rerun the script, or you can edit `~/.config/home-manager/home.nix` and run the special `rrhm` command

Now `nix develop` in special repos should work. You will probably need
```
    "rust-analyzer.cargo.extraEnv": {
        "NIX_PROFILES": "/nix/var/nix/profiles/default ${userHome}/.nix-profile",
        "PATH": "${userHome}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${env:PATH}"
    }
```
to get rust-analyzer to work. (find VSCode Settings and click the small "Open Settings (JSON)" icon in the top right). If this is not working, you can use the `nix_env.sh` script and extract just the `PATH` part and put that as the string following `"PATH":`.

To install docker on CentOS like systems,
`sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
`sudo systemctl enable --now docker`
`sudo usermod -aG docker $USER` To enable usage without sudo
and relogin.

One time, I saw a very hard to debug issue where I needed to hard relogin with `sudo loginctl terminate-user $USER` for some reason, and there was a mismatch in the docker GIDs that had to be fixed with `sudo groupmod -g {correct GID} docker`.

To configure git, fill in the quotes
```
git config --global user.name ""
bash-5.2$ git config --global user.email ""
```

