#!/bin/bash
#
# Effie OS ISO Builder
# Builds the full ~6GB offline bootable installer ISO using the official Omarchy/Effie pipeline,
# with automated Configurator wizard, offline package mirror, and QEMU test support.
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
EFFIE_ISO_DIR=$(cd -- "$ROOT/../effie-iso" 2>/dev/null && pwd || true)
EFFIE_PKGS_DIR=$(cd -- "$ROOT/../effie-pkgs" 2>/dev/null && pwd || true)
RELEASE_DIR="$ROOT/release"
BUILD_DIR="$ROOT/build"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Builds a complete, bootable Effie OS installer ISO image containing the latest local code
from this repository, the interactive Configurator wizard, and the offline package mirror (~6GB).

Options:
  --full, --offline (default)  Build the full ~6GB offline distribution ISO via effie-iso pipeline
  --minimal, --standalone      Build a lightweight live test ISO directly on host using mkarchiso
  --clean                      Clean all previous build artifacts, caches, and work directories
  --no-cache                   Do not use Docker/package cache when building full ISO
  -o, --output DIR             Directory to store the final ISO (default: release/)
  -h, --help                   Show this help message

Examples:
  # 1. Build the official 6GB offline installer ISO from local source:
  ./scripts/build-iso.sh

  # 2. Clean build:
  ./scripts/build-iso.sh --clean

  # 3. Test in QEMU after build:
  ./scripts/run-qemu.sh
USAGE
}

MODE="full"
CLEAN=0
NO_CACHE=0
EXTRA_ARGS=()

while (( $# > 0 )); do
  case "$1" in
    --full|--offline)
      MODE="full"
      shift
      ;;
    --minimal|--standalone)
      MODE="minimal"
      shift
      ;;
    --clean)
      CLEAN=1
      EXTRA_ARGS+=("--no-cache")
      shift
      ;;
    --no-cache)
      NO_CACHE=1
      EXTRA_ARGS+=("--no-cache")
      shift
      ;;
    -o|--output)
      RELEASE_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

mkdir -p "$RELEASE_DIR" "$BUILD_DIR"

if [[ "$MODE" == "full" ]]; then
  if [[ -z "$EFFIE_ISO_DIR" || ! -f "$EFFIE_ISO_DIR/bin/omarchy-iso-make" || -z "$EFFIE_PKGS_DIR" ]]; then
    echo "WARNING: Official effie-iso or effie-pkgs repository not found beside effie-os." >&2
    echo "Falling back to standalone host ISO build..." >&2
    MODE="minimal"
  fi
fi

if [[ "$MODE" == "full" ]]; then
  echo "========================================================"
  echo "  Building Full Effie OS 6GB Offline Installer ISO"
  echo "  Source Checkout : $ROOT"
  echo "  PKGS Checkout   : $EFFIE_PKGS_DIR"
  echo "  ISO Builder     : $EFFIE_ISO_DIR"
  echo "  Output Dir      : $RELEASE_DIR"
  echo "========================================================"

  ISO_MAKE_CMD=(
    "$EFFIE_ISO_DIR/bin/omarchy-iso-make"
    --local-source "$ROOT" "$EFFIE_PKGS_DIR"
    --keep-pkg-cache
    --no-boot-offer
  )

  if (( NO_CACHE )) || (( CLEAN )); then
    ISO_MAKE_CMD+=(--no-cache)
  fi

  (
    cd "$EFFIE_ISO_DIR"
    "${ISO_MAKE_CMD[@]}" "${EXTRA_ARGS[@]}"
  )

  # Copy/link the generated ISO into effie-os release/ directory
  LATEST_ISO=$(ls -t "$EFFIE_ISO_DIR/release"/*.iso 2>/dev/null | head -1 || true)
  if [[ -n "$LATEST_ISO" && -f "$LATEST_ISO" ]]; then
    ISO_BASENAME=$(basename "$LATEST_ISO")
    cp -u "$LATEST_ISO" "$RELEASE_DIR/$ISO_BASENAME"
    (
      cd "$RELEASE_DIR"
      sha256sum "$ISO_BASENAME" > "${ISO_BASENAME}.sha256"
    )

    echo "========================================================"
    echo "  Effie OS Official Offline ISO successfully created!"
    echo "  ISO Path     : $RELEASE_DIR/$ISO_BASENAME"
    echo "  Size         : $(du -h "$RELEASE_DIR/$ISO_BASENAME" | cut -f1)"
    echo "  SHA-256      : $(cat "$RELEASE_DIR/${ISO_BASENAME}.sha256" | cut -d' ' -f1)"
    echo "========================================================"
    echo "  To test in QEMU run:"
    echo "    ./scripts/run-qemu.sh"
    echo "========================================================"
    exit 0
  fi
fi

# Fallback: Standalone Minimal Build on Host
echo "==> Building standalone live test ISO on host..."
PACKAGING_DIR="$ROOT/packaging"
PROFILE_TEMPLATE_DIR="$ROOT/iso/profile"
LOCAL_REPO_DIR="$BUILD_DIR/repo"
WORK_DIR="$BUILD_DIR/archiso-work"
STAGED_PROFILE_DIR="$BUILD_DIR/archiso-profile"

if (( CLEAN )); then
  rm -rf "$LOCAL_REPO_DIR" "$STAGED_PROFILE_DIR"
  if [[ -d "$WORK_DIR" ]]; then
    sudo rm -rf "$WORK_DIR"
  fi
fi

echo "==> [1/4] Building packages from local source..."
"$PACKAGING_DIR/build-packages.sh" "$LOCAL_REPO_DIR"

echo "==> [2/4] Staging Archiso profile..."
rm -rf "$STAGED_PROFILE_DIR"
mkdir -p "$STAGED_PROFILE_DIR"
cp -a /usr/share/archiso/configs/releng/. "$STAGED_PROFILE_DIR/"
cp -f "$PROFILE_TEMPLATE_DIR/profiledef.sh" "$STAGED_PROFILE_DIR/profiledef.sh"

cat > "$STAGED_PROFILE_DIR/pacman.conf" <<EOF
[options]
Architecture = auto
HoldPkg = pacman glibc
ParallelDownloads = 5
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[effie-local]
SigLevel = Optional TrustAll
Server = file://${LOCAL_REPO_DIR}

[omarchy]
SigLevel = Optional TrustAll
Server = https://pkgs.omarchy.org/stable/\$arch

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

cat >> "$STAGED_PROFILE_DIR/packages.x86_64" <<'EOF'
omarchy-settings
omarchy
omarchy-keyring
hyprland
quickshell
uwsm
sddm
xdg-desktop-portal-hyprland
wireplumber
pipewire
pipewire-pulse
gnome-keyring
ttf-jetbrains-mono-nerd-basic
foot
foot-terminfo
gum
jq
tmux
git
curl
wget
rsync
htop
inxi
fastfetch
qemu-guest-agent
EOF
sort -u "$STAGED_PROFILE_DIR/packages.x86_64" -o "$STAGED_PROFILE_DIR/packages.x86_64"

AIROOTFS="$STAGED_PROFILE_DIR/airootfs"
mkdir -p "$AIROOTFS/etc/systemd/system/multi-user.target.wants"
mkdir -p "$AIROOTFS/etc/ssh/sshd_config.d"
mkdir -p "$AIROOTFS/etc/mkinitcpio.conf.d"
mkdir -p "$AIROOTFS/etc/pacman.d/hooks"
mkdir -p "$AIROOTFS/usr/local/bin"
mkdir -p "$AIROOTFS/root"

if [[ -d "$PROFILE_TEMPLATE_DIR/airootfs" ]]; then
  cp -a "$PROFILE_TEMPLATE_DIR/airootfs/." "$AIROOTFS/"
fi

cat > "$AIROOTFS/etc/mkinitcpio.conf.d/99-archiso.conf" <<'EOF'
HOOKS=(base udev microcode modconf kms memdisk archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs block filesystems keyboard)
COMPRESSION="zstd"
COMPRESSION_OPTIONS=(-15)
EOF

ln -sf /usr/lib/systemd/system/sshd.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/sshd.service"
ln -sf /usr/lib/systemd/system/qemu-guest-agent.service "$AIROOTFS/etc/systemd/system/multi-user.target.wants/qemu-guest-agent.service"

cat > "$AIROOTFS/etc/ssh/sshd_config.d/10-effie-live.conf" <<'EOF'
PermitRootLogin yes
PermitEmptyPasswords yes
EOF
sed -i 's|^root:.*|root::14871::::::|' "$AIROOTFS/etc/shadow"

echo "==> [3/4] Building ISO image with mkarchiso (sudo required)..."
mkdir -p "$WORK_DIR"
if [[ -d "$WORK_DIR" && ! -f "$WORK_DIR/iso/arch/boot/x86_64/vmlinuz-linux" ]]; then
  sudo rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"
fi

sudo mkarchiso -v -w "$WORK_DIR" -o "$RELEASE_DIR" "$STAGED_PROFILE_DIR"

echo "==> [4/4] Verifying generated ISO..."
LATEST_ISO=$(ls -t "$RELEASE_DIR"/*.iso 2>/dev/null | head -1 || true)
if [[ -n "$LATEST_ISO" && -f "$LATEST_ISO" ]]; then
  (
    cd "$RELEASE_DIR"
    sha256sum "$(basename "$LATEST_ISO")" > "$(basename "$LATEST_ISO").sha256"
  )
  echo "========================================================"
  echo "  Standalone Effie OS ISO created: $LATEST_ISO"
  echo "========================================================"
fi
