#!/bin/bash
#
# Build Effie OS / Omarchy packages from local working tree into a local pacman repository.
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
DEST_DIR="${1:-$ROOT/build/repo}"
BUILD_WORK_DIR="$ROOT/build/packaging-tmp"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options] [dest-repo-dir]

Builds Arch Linux packages (omarchy-settings and omarchy) directly from the
current effie-os repository and generates a local pacman repository database.

Arguments:
  dest-repo-dir     Directory for built packages and repo DB (default: build/repo)

Options:
  --clean           Clean temporary build artifacts before building
  -h, --help        Show this help message

Example:
  ./packaging/build-packages.sh
  ./packaging/build-packages.sh /tmp/my-repo
USAGE
}

CLEAN=0
POSITIONAL=()
while (( $# > 0 )); do
  case "$1" in
    --clean)
      CLEAN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if (( ${#POSITIONAL[@]} > 0 )); then
  DEST_DIR="${POSITIONAL[0]}"
fi

mkdir -p "$DEST_DIR"
mkdir -p "$BUILD_WORK_DIR"

if (( CLEAN )); then
  echo "==> Cleaning old build artifacts in $DEST_DIR and $BUILD_WORK_DIR..."
  rm -rf "${BUILD_WORK_DIR:?}"/*
  rm -f "$DEST_DIR"/*.pkg.tar.* "$DEST_DIR"/effie-local.* "$DEST_DIR"/omarchy-local.*
fi

# Determine version string
BASE_VER="4.0.0.alpha"
if [[ -f "$ROOT/version" ]]; then
  BASE_VER=$(tr -d ' \n\r' < "$ROOT/version")
fi

SHORT_SHA=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "local")
DIRTY=""
if [[ -d "$ROOT/.git" ]] && [[ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ]]; then
  DIRTY=".dirty"
fi

# Pacman pkgver requires numbers, letters, dots, and underscores (no dashes)
PKG_VER="${BASE_VER//-/.}"

echo "========================================================"
echo "  Effie OS Package Builder"
echo "  Source Root : $ROOT"
echo "  Version     : $PKG_VER (Commit: $SHORT_SHA$DIRTY)"
echo "  Output Repo : $DEST_DIR"
echo "========================================================"

build_pkg() {
  local pkg_name="$1"
  local pkgbuild_src="$SCRIPT_DIR/pkgbuilds/$pkg_name"
  local work_dir="$BUILD_WORK_DIR/$pkg_name"

  echo "==> Building package: $pkg_name..."
  rm -rf "$work_dir"
  mkdir -p "$work_dir"
  cp -a "$pkgbuild_src/." "$work_dir/"

  # Update pkgver in PKGBUILD
  sed -i "s/^pkgver=.*/pkgver=${PKG_VER}/" "$work_dir/PKGBUILD"

  (
    cd "$work_dir"
    OMARCHY_SRC="$ROOT" makepkg -f --nodeps --skipchecksums --noconfirm
  )

  local built_pkg
  built_pkg=$(ls -t "$work_dir"/$pkg_name-*.pkg.tar.* 2>/dev/null | grep -v '\.sig$' | head -1 || true)
  if [[ -z $built_pkg || ! -f $built_pkg ]]; then
    echo "ERROR: Failed to build $pkg_name (no package artifact found in $work_dir)" >&2
    exit 1
  fi

  echo "==> Successfully built: $(basename "$built_pkg")"
  cp -f "$built_pkg" "$DEST_DIR/"
}

# 1. Build omarchy-settings first
build_pkg "omarchy-settings"

# 2. Build omarchy
build_pkg "omarchy"

# 3. Generate/Update Pacman Repository Database
echo "==> Creating / Updating repository database in $DEST_DIR..."
(
  cd "$DEST_DIR"
  rm -f effie-local.db* effie-local.files*
  repo-add -n -R effie-local.db.tar.zst *.pkg.tar.zst
  # Create standard symlinks without tar extension for pacman compat
  [[ -f effie-local.db.tar.zst ]] && ln -sf effie-local.db.tar.zst effie-local.db
  [[ -f effie-local.files.tar.zst ]] && ln -sf effie-local.files.tar.zst effie-local.files
)

echo "========================================================"
echo "  Packages successfully generated in $DEST_DIR:"
ls -lh "$DEST_DIR"/*.pkg.tar.*
echo "========================================================"
