#!/bin/zsh

# Installs the sync-env runner script silently
SCRIPT_DIR="$(cd "$(dirname "$0")" && cd .. && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-env"

if [ ! -f "$SYNC_SCRIPT" ]; then
  cat <<'EOF' > "$SYNC_SCRIPT"
#!/bin/zsh

echo "🔧 Running all patches in ./patches"

for patch in ./patches/*.sh; do
  echo "▶️  Running shell patch: $patch"
  zsh "$patch"
done
EOF

  chmod +x "$SYNC_SCRIPT"
fi

echo '✅ Patch applied script "sync-env" – internal runner for patch updates'
