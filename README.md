How to setup a whole development system from scratch in the minimum time:

use the boilerplate script to setup SSH key,

Use determinant systems installer to install nix:
`curl -fsSL https://install.determinate.systems/nix | sh -s -- install`

Run the boilerplate script again, may have to re login.

May need to add `PATH="$PATH:~/.nix-profile/bin:/nix/var/nix/profiles/default/bin"` to .bashrc and run `source .bashrc`

boilerplate home-manager setup script:

```
#!/usr/bin/env bash

GITHUB_CLI="false"
CONFIG_URL="";
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ecdsa"
CONFIG_DIR="$HOME/.config/home-manager"

# location of the user's nix and home-manager configs
NIX_HOME="$HOME/.config/home-manager"
NIX_STATE="$HOME/.local/state/nix"
HM_BACKUP_DIR="$HOME/.config/home-manager_backup_$(date +%Y%m%d_%H%M%S)"

################################################### --- GitHub Repo Setup --- ###########################
#########################################################################################################

# check if gh cli is installed and logged in
if command -v gh &> /dev/null
then
    if gh auth status &> /dev/null
    then
        GITHUB_CLI="true"
    fi
fi

if [ "$GITHUB_CLI" = "true" ]
then
    echo "GitHub CLI detected and authenticated."
    TEMPLATE_REPO="NoeticNet/NoetDevLab"

    # prompt user for repo name (default to template name)
    read -p "Enter a name for your new repository [default: NoetDevLab]: " REPO_NAME < /dev/tty
    REPO_NAME=${REPO_NAME:-NoetDevLab}

    # check if repo already exists under the authenticated user/org
    if gh repo view "$REPO_NAME" &> /dev/null
    then
        echo "Repository '$REPO_NAME' already exists."
    else
        echo "Creating repository '$REPO_NAME' from template '$TEMPLATE_REPO'..."
        gh repo create "$REPO_NAME" --template "$TEMPLATE_REPO" --public
    fi

    # get repo URL (works for both user/org)
    CONFIG_URL=$(gh repo view "$REPO_NAME" --json url -q .url)
    echo "Repository URL: $CONFIG_URL"

else
    echo "GitHub CLI is not installed or not logged in."
    echo "Please create a repo from template located at https://github.com/NoeticNet/NoetDevLab manually."
    read -p "After creating the repo, please enter the repository URL: " CONFIG_URL < /dev/tty
fi

echo "CONFIG_URL set to: $CONFIG_URL"

################################################### --- SSH Setup --- ###########################
#################################################################################################


# create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating ~/.ssh directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# check if a private key already exists
if [ -f "$SSH_KEY" ]; then
    echo "An SSH key already exists at $SSH_KEY"
else
    echo "No SSH key found."

    read -p "Would you like to create a new SSH key? [Y/n]: " CREATE_KEY < /dev/tty
    CREATE_KEY=${CREATE_KEY:-Y}

    if [[ "$CREATE_KEY" =~ ^[Yy]$ ]]; then
        # check if TPM support is available for ECC keys
        if ssh-keygen -Q tpm &>/dev/null; then
            echo "TPM support detected — generating TPM-backed ECC key..."
            read -s -p "Enter a passphrase for your new SSH key (or leave blank for none): " KEY_PASS
            echo ""
            if [ -n "$KEY_PASS" ]; then
                ssh-keygen -t ecdsa-sk -f "$SSH_KEY" -C "$(whoami)@$(hostname)" -N "$KEY_PASS"
            else
                ssh-keygen -t ecdsa-sk -f "$SSH_KEY" -C "$(whoami)@$(hostname)" -N ""
            fi
        else
            echo "No TPM support detected — generating regular ECC key..."
            read -s -p "Enter a passphrase for your new SSH key (or leave blank for none): " KEY_PASS
            echo ""
            if [ -n "$KEY_PASS" ]; then
                ssh-keygen -t ecdsa -b 521 -f "$SSH_KEY" -C "$(whoami)@$(hostname)" -N "$KEY_PASS"
            else
                ssh-keygen -t ecdsa -b 521 -f "$SSH_KEY" -C "$(whoami)@$(hostname)" -N ""
            fi
        fi
    else
        echo "Please provide your existing private key file path (e.g., /path/to/id_rsa):"
        read -p "Path: " EXISTING_KEY < /dev/tty
        if [ -f "$EXISTING_KEY" ]; then
            cp "$EXISTING_KEY" "$SSH_KEY"
            chmod 600 "$SSH_KEY"
            echo "SSH key copied to $SSH_KEY"
        else
            echo "Provided key path does not exist. Please rerun this step when you have a valid key."
        fi
    fi
fi

# ensure permissions are correct
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR"/* 2>/dev/null || true

echo "SSH setup complete. Public key:"
if [ -f "${SSH_KEY}.pub" ]; then
    cat "${SSH_KEY}.pub"
else
    echo "No public key found."
fi

################################################### clone home-manager config #############################
###########################################################################################################

echo "Cloning repository into $CONFIG_DIR..."

# ensure parent directories exist
mkdir -p "$(dirname "$CONFIG_DIR")"

if [ -d "$CONFIG_DIR" ]; then
    echo "Directory $CONFIG_DIR already exists."
    read -p "Would you like to overwrite it? [y/N]: " OVERWRITE < /dev/tty
    OVERWRITE=${OVERWRITE:-N}
    if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
    else
        echo "Keeping existing directory. Exiting clone step."
    fi
fi

if [ ! -d "$CONFIG_DIR" ]; then
    git clone "$CONFIG_URL" "$CONFIG_DIR"
fi

# --- Replace username in vars.nix ---
VARS_FILE="$CONFIG_DIR/vars.nix"

if [ -f "$VARS_FILE" ]; then
    CURRENT_USER=$(whoami)
    echo "Updating username in $VARS_FILE to \"$CURRENT_USER\"..."
    sed -i.bak "s/username = \"Noet\";/username = \"$CURRENT_USER\";/" "$VARS_FILE"
    echo "Done. Backup saved as $VARS_FILE.bak"
else
    echo "Warning: vars.nix not found at expected path ($VARS_FILE)"
fi

################################################### --- Home Manager Setup --- ################################
###############################################################################################################

echo "Initializing Home Manager configuration..."
# backup existing configs if they exist
if [ -d "$NIX_HOME" ] || [ -d "$NIX_STATE" ]; then
    echo "Backing up existing Home Manager configuration..."
    mkdir -p "$HM_BACKUP_DIR"

    [ -d "$NIX_HOME" ] && cp -r "$NIX_HOME" "$HM_BACKUP_DIR/home-manager" 2>/dev/null
    [ -d "$NIX_STATE" ] && cp -r "$NIX_STATE" "$HM_BACKUP_DIR/nix_state" 2>/dev/null

    echo "Backup complete at: $HM_BACKUP_DIR"
fi

# ensure we're in the right directory
cd "$NIX_HOME" || {
    echo "Error: Cannot access $NIX_HOME"
    exit 1
}

echo "Running Home Manager initialization..."
nix run home-manager/master -- init --switch --impure -b "bak-$(date +%Y%m%d%H%M%S)"

if [ $? -eq 0 ]; then
    echo "✅ Home Manager initialized successfully."
else
    echo "⚠️ Home Manager initialization failed. You can restore your backup from:"
    echo "   $HM_BACKUP_DIR"
fi
```
