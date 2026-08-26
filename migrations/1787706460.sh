echo "Configure Superfile theme integration"

# Ensure Superfile's theme directory exists and symlinks the Omarchy theme
mkdir -p "$HOME/.config/superfile/theme"
ln -snf "$HOME/.local/state/omarchy/current/theme/superfile.toml" "$HOME/.config/superfile/theme/omarchy.toml"

# Ensure Superfile config specifies the omarchy theme
if [[ -f $HOME/.config/superfile/config.toml ]]; then
  if grep -q '^[[:space:]]*theme[[:space:]]*=' "$HOME/.config/superfile/config.toml"; then
    sed -i -E 's/^[[:space:]]*theme[[:space:]]*=.*/theme = "omarchy"/' "$HOME/.config/superfile/config.toml"
  fi
elif [[ -f ${OMARCHY_PATH:-/usr/share/omarchy}/config/superfile/config.toml ]]; then
  mkdir -p "$HOME/.config/superfile"
  cp "${OMARCHY_PATH:-/usr/share/omarchy}/config/superfile/config.toml" "$HOME/.config/superfile/config.toml"
fi

# Render superfile.toml if the current theme hasn't generated it yet
if [[ ! -e $HOME/.local/state/omarchy/current/theme/superfile.toml ]]; then
  omarchy-theme-refresh >/dev/null 2>&1 || true
fi
