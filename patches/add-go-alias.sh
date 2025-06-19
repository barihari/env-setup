#!/bin/zsh

ZSHRC="$HOME/.zshrc"

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

append_to_zshrc_once "# === go alias ===" '
# === go alias ===
go() {
  local starter_dir="$HOME/sites/my-starter"
  if [ ! -d "$starter_dir/.git" ]; then
    echo "❌ my-starter not found at $starter_dir"
    echo "Run: starter project-name to get a fresh copy."
    return 1
  fi
  echo "🔄 Pulling latest updates in $starter_dir..."
  git -C "$starter_dir" pull
}
'

echo '✅ Patch applied alias "go" – pulls updates for my-starter'
