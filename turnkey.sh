# turnkey.sh - Version 1.0.0
echo "⚠️  This script will install tools and make system changes on your Mac."
echo "Do you want to continue? (y/n)"
read -r confirm
if [[ "$confirm" != "y" ]]; then
  echo "❌ Cancelled by user."
  exit 1
fi

# === Turnkey Setup Script Overview ===
# turnkey.sh - Version 1.0.0
# This script sets up your entire dev environment from scratch on a new Mac:
#
# SYSTEM PREP
# 1. Installs Xcode CLI Tools
# 2. Installs Homebrew (if missing)
# 3. Runs your Brewfile to install CLI tools (e.g. ghostty)
#
# SHELL CONFIGURATION
# 4. Installs Oh My Zsh and sets Zsh plugins
#
# SSH SETUP
# 5. Creates ~/.ssh, installs your SSH keys, and sets up ssh-agent + GitHub config
#
# ENV VARIABLES
# 6. Creates a .env file (if missing), loads it, and links to your .zshrc
#
# NODE/NVM
# 7. Warns if no .nvmrc exists in a Node project
#
# PROJECT BOILERPLATE
# 8. Adds a 'starter' alias that clones your my-starter repo into ~/sites/project-name,
#    sets the upstream, enters the folder, and pulls latest updates
#
# CLI TOOLING
# 9. Installs pnpm and yarn globally
#
# ZSH AUTOMATION
# 10. Adds autoload logic to .zshrc for switching Node versions based on .nvmrc
# 11. Adds a 'go' alias to pull upstream updates into any project cloned from my-starter
#
# CURSOR CLI INTEGRATION
# 12. Links the Cursor CLI (if available) and adds a 'c' alias for launching it from terminal

### SYSTEM PREP ###
### SYSTEM PREP ###

# 1. Install Xcode Command Line Tools
xcode-select --install

# 2. Install Homebrew if not installed
if command -v brew &> /dev/null; then
  echo "Homebrew already installed. Skipping."
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. Run Brewfile to install CLI tools and apps
echo "Running Brewfile to install CLI tools..."
brew bundle --file=./Brewfile

### SHELL CONFIGURATION ###

echo "Installing Oh My Zsh..."

# 4. Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 5. Enable common Oh My Zsh plugins
ZSHRC="$HOME/.zshrc"
if ! grep -q "plugins=(git node yarn npm" "$ZSHRC"; then
  sed -i '' 's/plugins=(.*)/plugins=(git node yarn npm zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
fi

### SSH KEY SETUP ###

echo "Setting up SSH config..."

# 6. Create SSH folder and config
mkdir -p ~/.ssh
cp ./id_ed25519 ~/.ssh/id_ed25519
cp ./id_ed25519.pub ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

cat <<EOF > ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
EOF

# 7. Add key to macOS Keychain
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 8. Test GitHub auth
ssh -T git@github.com

### ENVIRONMENT VARIABLES ###

echo "Checking for .env file..."

# 9. Create or update .env securely
if [ ! -f ~/.env ]; then
  cat <<EOF2 > ~/.env
# Add your API tokens below
# Example:
# OPENAI_API_KEY=sk-abc123
# STRIPE_SECRET_KEY=sk_live_xyz
EOF2
  echo "Created starter ~/.env file."
fi

# 10. Load environment variables now
export $(grep -v '^#' ~/.env | xargs)

# 11. Link env loading to .zshrc if not already linked
if ! grep -q "source ~/.env" "$ZSHRC"; then
  echo "[ -f ~/.env ] && export \$(grep -v '^#' ~/.env | xargs)" >> "$ZSHRC"
  echo "Linked .env to .zshrc"
fi

### NVM + NODE VERSION CHECK ###

# 12. Warn if inside a Node project and .nvmrc is missing
if [ -f package.json ] && [ ! -f .nvmrc ]; then
  echo "Detected a Node project without an .nvmrc file. Create one to pin your Node version:"
  echo "    echo "18" > .nvmrc && nvm install"
fi

### STARTER PROJECT TEMPLATE ###

echo "Cloning your my-starter boilerplate into ~/sites..."

# 13. Clone boilerplate into ~/sites/my-starter
SITES_DIR="$HOME/sites"
TARGET_STARTER="$SITES_DIR/my-starter"

mkdir -p "$SITES_DIR"
git clone git@github.com:barihari/my-starter.git "$TARGET_STARTER"
echo "Cloned starter project into ~/sites/my-starter via SSH."

### CLI TOOLING ###

echo "Installing global CLI tools (pnpm, yarn)..."

# 14. Install pnpm and yarn globally
npm install -g pnpm
npm install -g yarn

### ZSHRC: AUTO-LOAD .NVMRC ###

echo "Setting up auto-nvm use behavior in .zshrc..."

# 15. Add auto-nvm use behavior to .zshrc
if ! grep -q "load-nvmrc" "$ZSHRC"; then
  cat <<'EOF3' >> "$ZSHRC"

# Auto-load .nvmrc Node version on directory change
autoload -U add-zsh-hook

load-nvmrc() {
  if nvm --version &>/dev/null && [ -f .nvmrc ]; then
    nvm use &>/dev/null
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc
EOF3
  echo "Added auto-nvm use logic to .zshrc"
fi

### INSTALL CURSOR CLI SHORTCUT ###

# Attempt to link Cursor CLI for Apple Silicon systems
if [ -f "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]; then
  if [ ! -f "/opt/homebrew/bin/cursor" ]; then
    echo "Linking Cursor CLI to /opt/homebrew/bin/cursor..."
    sudo ln -s /Applications/Cursor.app/Contents/Resources/app/bin/cursor /opt/homebrew/bin/cursor
  else
    echo "Cursor CLI already linked."
  fi
else
  echo "Cursor CLI binary not found at expected location."
fi

# Add short alias 'c' for launching Cursor
if ! grep -q "alias c=" "$ZSHRC"; then
  echo "alias c='cursor'" >> "$ZSHRC"
  echo "Added alias 'c' for Cursor to .zshrc"
fi


### DONE ###
echo "Full dev environment is ready to go. Open Ghostty and start coding."
echo "Use 'starter project-name' to start a fresh coding project."
echo "Use 'c .' to launch Cursor in the current folder."