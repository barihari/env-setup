#!/bin/zsh
# turnkey.sh - Version 1.0.1

echo "⚠️  This script will install tools and make system changes on your Mac."
echo "Do you want to continue? (y/n)"
read -r confirm
if [[ "$confirm" != "y" ]]; then
  echo "❌ Cancelled by user."
  exit 1
fi

ZSHRC="$HOME/.zshrc"
# Helper to safely add content to .zshrc without duplication
append_to_zshrc_once() {
  local label="$1"
  local block="$2"
  if ! grep -q "$label" "$ZSHRC"; then
    echo "$block" >> "$ZSHRC"
    echo "✅ Added $label to .zshrc"
  else
    echo "ℹ️  $label already exists in .zshrc. Skipping."
  fi
}


SITES_DIR="$HOME/sites"
TARGET_STARTER="$SITES_DIR/my-starter"

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

# 3. Ensure /opt/homebrew/bin is in PATH
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "$ZSHRC"
  export PATH="/opt/homebrew/bin:$PATH"
  echo "✅ Added /opt/homebrew/bin to PATH and updated .zshrc"
fi

# 4. Run Brewfile to install CLI tools
echo "Running Brewfile to install CLI tools..."
brew bundle --file=./Brewfile --verbose

### SHELL CONFIGURATION ###

echo "Installing Oh My Zsh..."

# 6. Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh without modifying your .zshrc..."
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 7. Enable common Oh My Zsh plugins
if ! grep -q "plugins=(git node yarn npm" "$ZSHRC"; then
  sed -i '' 's/plugins=(.*)/plugins=(git node yarn npm zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
fi

### SSH KEY SETUP ###

echo "Setting up SSH config..."

# 8. Create SSH folder and install keys
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

# 9. Add key to macOS Keychain
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 10. Test GitHub auth
ssh -T git@github.com

### ENVIRONMENT VARIABLES ###

echo "Checking for .env file..."

# 11. Create or update .env securely
if [ ! -f ~/.env ]; then
  cat <<EOF2 > ~/.env
# Add your API tokens below
# Example:
# OPENAI_API_KEY=sk-abc123
# STRIPE_SECRET_KEY=sk_live_xyz
EOF2
  echo "Created starter ~/.env file."
fi

# 12. Load environment variables now
export $(grep -v '^#' ~/.env | xargs)

# 13. Link env loading to .zshrc
if ! grep -q "source ~/.env" "$ZSHRC"; then
  echo "[ -f ~/.env ] && export \$(grep -v '^#' ~/.env | xargs)" >> "$ZSHRC"
  echo "Linked .env to .zshrc"
fi

### NVM + NODE VERSION CHECK ###

# 14. Warn if inside a Node project and .nvmrc is missing
if [ -f package.json ] && [ ! -f .nvmrc ]; then
  echo "Detected a Node project without an .nvmrc file. Create one to pin your Node version:"
  echo "    echo '18' > .nvmrc && nvm install"
fi
### STARTER PROJECT TEMPLATE ###

echo "📦 Setting up latest my-starter in ~/sites..."

mkdir -p "$SITES_DIR"

if [ -d "$TARGET_STARTER" ]; then
  echo "🗑  Removing existing $TARGET_STARTER"
  rm -rf "$TARGET_STARTER"
fi

echo "📥 Cloning fresh my-starter from GitHub..."
git clone git@github.com:barihari/my-starter.git "$TARGET_STARTER"
echo "✅ Cloned my-starter into $TARGET_STARTER"

# Add 'starter' function to .zshrc
append_to_zshrc_once "# === starter function ===" '
# === starter function ===
starter() {
  if [ -z "$1" ]; then
    echo "❌ Usage: starter project-name"
    return 1
  fi
  mkdir -p "$HOME/sites/$1"
  cp -R "$HOME/sites/my-starter/." "$HOME/sites/$1"
  cd "$HOME/sites/$1" || return
  git init
  git remote add origin git@github.com:barihari/$1.git
  echo "✅ Project $1 created at ~/sites/$1"
}
'

### CLI TOOLING ###

echo "Installing CLI tools (pnpm, yarn) via Homebrew..."

# 16. Use Homebrew to install pnpm and yarn to avoid EEXIST errors
brew install pnpm
brew install yarn

### ZSHRC: AUTO-LOAD .NVMRC ###

echo "Setting up auto-nvm use behavior in .zshrc..."

# 17. Add .nvmrc auto-use logic
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

echo "Would you like to manually install nvm for Node version management? (y/n)"
read -r install_nvm
if [[ "$install_nvm" == "y" ]]; then
  export NVM_DIR="$HOME/.nvm"
  if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm manually..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Add to .zshrc if not already present
    if ! grep -q 'export NVM_DIR="$HOME/.nvm"' "$ZSHRC"; then
      echo 'export NVM_DIR="$HOME/.nvm"' >> "$ZSHRC"
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$ZSHRC"
      echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$ZSHRC"
      echo "Linked nvm to .zshrc"
    fi

    echo "✅ nvm installed and configured."
  else
    echo "nvm already installed. Skipping."
  fi
else
  echo "⚠️  Skipping nvm install. You can always install it manually with:"
  echo "    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
fi

### INSTALL CURSOR CLI SHORTCUT ###

# 18. Link Cursor CLI for Apple Silicon systems
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

# 19. Add 'c' alias for launching Cursor
if ! grep -q "alias c=" "$ZSHRC"; then
  echo "alias c='cursor'" >> "$ZSHRC"
  append_to_zshrc_once "# === Cursor alias ===" '
# === Cursor alias ===
alias c="cursor"
'
echo "Added alias 'c' for Cursor to .zshrc"
fi

### COLIMA + DOCKER ###

# 20. Verify Colima and Docker CLI installs
if ! command -v colima &> /dev/null; then
  echo "Colima not found. Make sure 'brew install colima docker' ran successfully."
fi

if ! command -v docker &> /dev/null; then
  echo "Docker CLI not found. Check that 'brew install docker' completed."
fi

echo "Colima and Docker CLI are installed, but Colima is not running by default."
echo "Run 'colima start' when a project requires containers."

### DONE ###
echo "Reloading .zshrc for immediate use..."
source "$ZSHRC"

# Apply all patches (catch-all loop)
for patch in ./patches/*.sh; do
  zsh "$patch"
done

# Final output
source "$ZSHRC"
echo "✅ Full dev environment is ready."
echo "✅ All patches applied successfully."
echo "➡️  Use 'starter project-name' to scaffold a new project."
echo "➡️  Use 'c .' to launch Cursor in the current folder."