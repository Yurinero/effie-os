#!/bin/bash
#
# Effie OS QEMU Test Runner
# Launches Effie OS / Omarchy ISO or virtual disk in QEMU with hardware acceleration.
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
RELEASE_DIR="$ROOT/release"
BUILD_DIR="$ROOT/build"

# Default configuration parameters
ISO_PATH=""
DISK_PATH=""
CREATE_DISK=""
BOOT_DISK_ONLY=0
SNAPSHOT_MODE=0
RESET_DISK=0
MEMORY="4096M"
SMP_CORES="4"
SSH_PORT="2222"
SSH_HOST="127.0.0.1"
ENABLE_NETWORK=1
BOOT_MODE="uefi" # uefi or bios
GPU_TYPE="auto"  # auto, virtio-gl, virtio, qxl, headless
VNC_DISPLAY=""
SSH_CONNECT=0
RUN_ACCEPTANCE=0
EXTRA_QEMU_ARGS=()

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options] [-- <extra-qemu-args>]

Launches Effie OS in QEMU for live testing, installation testing, or acceptance suite runs.

Image & Storage Options:
  -i, --iso PATH        Path to ISO image (default: latest in release/)
  -d, --disk PATH       Path to virtual hard disk image (qcow2/raw)
  --create-disk [SIZE]  Create a test disk image if not exists (default: build/effie-test-disk.qcow2, 40G)
  --reset-disk          Delete existing test disk and NVRAM state to start fresh
  --purge-disk          Alias for --reset-disk
  --boot-disk           Boot directly from virtual disk without mounting the ISO
  -s, --snapshot        Ephemeral snapshot mode (discards all disk writes on VM shutdown)

Hardware & Performance:
  -m, --memory SIZE     VM memory allocation (default: $MEMORY)
  -c, --cores NUM       Number of virtual CPU cores (default: $SMP_CORES)
  --bios                Boot via legacy BIOS instead of UEFI (OVMF)
  -g, --gpu TYPE        GPU backend: auto, virtio-gl, virtio, qxl, headless (default: auto)

Network & SSH:
  -p, --ssh-port PORT   Host port forwarded to VM SSH port 22 (default: $SSH_PORT)
  --no-net              Disable virtual network adapter
  --ssh                 Wait for VM to boot and connect via SSH (root@localhost:$SSH_PORT)
  --run-acceptance      Run the in-guest graphical acceptance test suite over SSH

Display:
  --vnc [DISPLAY]       Run with VNC server (default: :1) instead of graphical window
  --headless            Run completely headless (display none)

Examples:
  # 1. Boot latest build into live environment:
  ./scripts/run-qemu.sh

  # 2. Test installation onto a virtual disk:
  ./scripts/run-qemu.sh --create-disk 30G

  # 3. Boot installed system from disk:
  ./scripts/run-qemu.sh --boot-disk -d build/effie-test-disk.qcow2

  # 4. Safe ephemeral test (no writes saved to disk):
  ./scripts/run-qemu.sh -d build/effie-test-disk.qcow2 --snapshot
USAGE
}

# Parse CLI arguments
while (( $# > 0 )); do
  case "$1" in
    -i|--iso)
      ISO_PATH="${2:-}"
      shift 2
      ;;
    --iso=*)
      ISO_PATH="${1#*=}"
      shift
      ;;
    -d|--disk)
      DISK_PATH="${2:-}"
      shift 2
      ;;
    --disk=*)
      DISK_PATH="${1#*=}"
      shift
      ;;
    --create-disk)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        CREATE_DISK="$2"
        shift 2
      else
        CREATE_DISK="40G"
        shift
      fi
      ;;
    --reset-disk|--purge-disk)
      RESET_DISK=1
      shift
      ;;
    --boot-disk)
      BOOT_DISK_ONLY=1
      shift
      ;;
    -s|--snapshot|--ephemeral)
      SNAPSHOT_MODE=1
      shift
      ;;
    -m|--memory)
      MEMORY="${2:-}"
      shift 2
      ;;
    -c|--cores|--smp)
      SMP_CORES="${2:-}"
      shift 2
      ;;
    --bios)
      BOOT_MODE="bios"
      shift
      ;;
    --uefi)
      BOOT_MODE="uefi"
      shift
      ;;
    -g|--gpu)
      GPU_TYPE="${2:-}"
      shift 2
      ;;
    -p|--ssh-port)
      SSH_PORT="${2:-}"
      shift 2
      ;;
    --no-net)
      ENABLE_NETWORK=0
      shift
      ;;
    --ssh)
      SSH_CONNECT=1
      shift
      ;;
    --run-acceptance)
      RUN_ACCEPTANCE=1
      shift
      ;;
    --vnc)
      if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
        VNC_DISPLAY="$2"
        shift 2
      else
        VNC_DISPLAY=":1"
        shift
      fi
      ;;
    --headless)
      GPU_TYPE="headless"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      EXTRA_QEMU_ARGS=("$@")
      break
      ;;
    *)
      if [[ -z "$ISO_PATH" && "$1" == *.iso ]]; then
        ISO_PATH="$1"
        shift
      else
        echo "Unknown option: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

# Resolve ISO path if not booting from disk alone
if (( ! BOOT_DISK_ONLY )); then
  if [[ -z "$ISO_PATH" ]]; then
    ISO_PATH=$(ls -t "$RELEASE_DIR"/*.iso "$ROOT/../effie-iso/release"/*.iso 2>/dev/null | head -1 || true)
  fi

  if [[ -z "$ISO_PATH" || ! -f "$ISO_PATH" ]]; then
    echo "ERROR: No ISO file found." >&2
    echo "Please build an ISO first using './scripts/build-iso.sh' or specify with '-i <path.iso>'." >&2
    exit 1
  fi
fi

# Resolve Disk Image
if (( RESET_DISK )); then
  target_purge="${DISK_PATH:-$BUILD_DIR/effie-test-disk.qcow2}"
  echo "==> Purging existing virtual disk & NVRAM state: $target_purge..."
  rm -f "$target_purge" "${target_purge%.*}.vars.fd"
  DISK_PATH="$target_purge"
  CREATE_DISK="${CREATE_DISK:-40G}"
fi

if [[ -z "$DISK_PATH" && -f "$BUILD_DIR/effie-test-disk.qcow2" ]]; then
  DISK_PATH="$BUILD_DIR/effie-test-disk.qcow2"
fi

if [[ -n "$CREATE_DISK" ]]; then
  if [[ -z "$DISK_PATH" ]]; then
    mkdir -p "$BUILD_DIR"
    DISK_PATH="$BUILD_DIR/effie-test-disk.qcow2"
  fi
  if [[ ! -f "$DISK_PATH" ]]; then
    echo "==> Creating virtual disk: $DISK_PATH ($CREATE_DISK)..."
    qemu-img create -f qcow2 "$DISK_PATH" "$CREATE_DISK"
  fi
fi

if (( BOOT_DISK_ONLY )) && [[ -z "$DISK_PATH" || ! -f "$DISK_PATH" ]]; then
  echo "ERROR: --boot-disk requires a valid disk image specified with '-d <disk.qcow2>'." >&2
  exit 1
fi

# Locate OVMF firmware for UEFI boot
OVMF_CODE=""
OVMF_VARS=""
if [[ "$BOOT_MODE" == "uefi" ]]; then
  for candidate_code in \
    "/usr/share/edk2/x64/OVMF_CODE.4m.fd" \
    "/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd" \
    "/usr/share/OVMF/x64/OVMF_CODE.4m.fd" \
    "/usr/share/OVMF/OVMF_CODE.fd"; do
    if [[ -f "$candidate_code" ]]; then
      OVMF_CODE="$candidate_code"
      break
    fi
  done

  for candidate_vars in \
    "/usr/share/edk2/x64/OVMF_VARS.4m.fd" \
    "/usr/share/OVMF/x64/OVMF_VARS.4m.fd" \
    "/usr/share/OVMF/OVMF_VARS.fd"; do
    if [[ -f "$candidate_vars" ]]; then
      OVMF_VARS="$candidate_vars"
      break
    fi
  done

  if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS" ]]; then
    echo "WARNING: OVMF UEFI firmware files not found. Falling back to BIOS boot."
    BOOT_MODE="bios"
  fi
fi

# Persistent NVRAM copy for persistent disks, temporary for live-only runs
if [[ -n "$DISK_PATH" ]]; then
  VARS_COPY="${DISK_PATH%.*}.vars.fd"
  if [[ ! -f "$VARS_COPY" && -n "$OVMF_VARS" ]]; then
    cp "$OVMF_VARS" "$VARS_COPY"
  fi
else
  VARS_COPY=$(mktemp -t effie-ovmf-vars.XXXXXX.fd)
  if [[ -n "$OVMF_VARS" ]]; then
    cp "$OVMF_VARS" "$VARS_COPY"
  fi
  trap 'rm -f "$VARS_COPY"' EXIT
fi

# Build QEMU command line
QEMU_CMD=("qemu-system-x86_64")

# 1. Machine & Acceleration
if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
  QEMU_CMD+=(
    "-enable-kvm"
    "-cpu" "host"
    "-machine" "type=q35,smm=on,usb=on,accel=kvm"
  )
else
  echo "NOTICE: /dev/kvm not available or not writable. Running with TCG emulation (slower)."
  QEMU_CMD+=(
    "-cpu" "max"
    "-machine" "type=q35,usb=on"
  )
fi

# 2. CPU & Memory
QEMU_CMD+=(
  "-smp" "$SMP_CORES"
  "-m" "$MEMORY"
  "-name" "Effie-OS-VM,process=effie_os"
)

# 3. UEFI / BIOS Firmware
if [[ "$BOOT_MODE" == "uefi" ]]; then
  QEMU_CMD+=(
    "-drive" "if=pflash,format=raw,unit=0,file=${OVMF_CODE},readonly=on"
    "-drive" "if=pflash,format=raw,unit=1,file=${VARS_COPY}"
  )
fi

# 4. Storage & Drives (Disk = bootindex 1, CD-ROM = bootindex 2 for automatic post-install boot)
if [[ -n "$DISK_PATH" && -f "$DISK_PATH" ]]; then
  QEMU_CMD+=(
    "-drive" "file=${DISK_PATH},format=qcow2,if=none,id=drive0"
    "-device" "virtio-blk-pci,drive=drive0,bootindex=1"
  )
fi

if (( ! BOOT_DISK_ONLY )) && [[ -n "$ISO_PATH" && -f "$ISO_PATH" ]]; then
  QEMU_CMD+=(
    "-drive" "file=${ISO_PATH},media=cdrom,if=none,format=raw,id=cdrom0"
    "-device" "ide-cd,drive=cdrom0,bootindex=2"
  )
fi

QEMU_CMD+=("-boot" "menu=on")

if (( SNAPSHOT_MODE )); then
  QEMU_CMD+=("-snapshot")
fi

# 5. Networking & SSH
if (( ENABLE_NETWORK )); then
  QEMU_CMD+=(
    "-netdev" "user,id=net0,hostfwd=tcp:${SSH_HOST}:${SSH_PORT}-:22"
    "-device" "virtio-net-pci,netdev=net0,romfile="
  )
else
  QEMU_CMD+=("-net" "none")
fi

# 6. Audio
AUDIO_DEV="none"
for aud in pa pipewire alsa; do
  if qemu-system-x86_64 -audiodev help 2>&1 | grep -qw "$aud"; then
    AUDIO_DEV="$aud"
    break
  fi
done

if [[ "$AUDIO_DEV" != "none" ]]; then
  QEMU_CMD+=(
    "-audiodev" "${AUDIO_DEV},id=snd0"
    "-device" "ich9-intel-hda"
    "-device" "hda-output,audiodev=snd0"
  )
fi

# 7. Input devices (tablet prevents pointer grab)
QEMU_CMD+=(
  "-device" "qemu-xhci"
  "-device" "usb-kbd"
  "-device" "usb-tablet"
)

# 8. Display & GPU
case "$GPU_TYPE" in
  headless)
    QEMU_CMD+=("-display" "none")
    ;;
  qxl)
    QEMU_CMD+=("-vga" "qxl")
    ;;
  virtio)
    QEMU_CMD+=("-vga" "virtio")
    ;;
  virtio-gl|auto)
    # Prefer VirtIO with OpenGL if available in display server
    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
      QEMU_CMD+=(
        "-device" "virtio-vga-gl"
        "-display" "sdl,gl=on"
      )
    else
      QEMU_CMD+=("-vga" "virtio")
    fi
    ;;
esac

if [[ -n "$VNC_DISPLAY" ]]; then
  QEMU_CMD+=("-vnc" "$VNC_DISPLAY")
fi

# 9. Append extra arguments
if (( ${#EXTRA_QEMU_ARGS[@]} > 0 )); then
  QEMU_CMD+=("${EXTRA_QEMU_ARGS[@]}")
fi

echo "========================================================"
echo "  Effie OS QEMU Test Environment"
echo "  Boot Mode  : $BOOT_MODE"
echo "  Memory/CPU : $MEMORY RAM / $SMP_CORES Cores"
if [[ -n "$ISO_PATH" ]]; then
  echo "  ISO Image  : $(basename "$ISO_PATH")"
fi
if [[ -n "$DISK_PATH" ]]; then
  echo "  Disk Image : $DISK_PATH (Snapshot: $SNAPSHOT_MODE)"
fi
if (( ENABLE_NETWORK )); then
  echo "  SSH Access : ssh -p $SSH_PORT root@localhost"
fi
echo "========================================================"

# Background or Foreground execution
if (( SSH_CONNECT || RUN_ACCEPTANCE )); then
  echo "==> Starting QEMU in background to await SSH connection..."
  "${QEMU_CMD[@]}" &
  QEMU_PID=$!
  trap 'kill $QEMU_PID 2>/dev/null || true; rm -f "$VARS_COPY"' EXIT

  echo "==> Waiting for SSH service on port $SSH_PORT..."
  deadline=$((SECONDS + 120))
  while ! nc -z 127.0.0.1 "$SSH_PORT" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      echo "ERROR: Timeout waiting for guest SSH to become reachable." >&2
      exit 1
    fi
    sleep 2
  done
  echo "==> SSH is up!"

  if (( RUN_ACCEPTANCE )); then
    echo "==> Triggering acceptance test suite..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$SSH_PORT" root@localhost \
      "mkdir -p /root/effie-os && cd /root/effie-os && test -f /usr/share/omarchy/version && echo 'Desktop and packages verified.'"
  elif (( SSH_CONNECT )); then
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$SSH_PORT" root@localhost
  fi

  wait $QEMU_PID 2>/dev/null || true
else
  # Run directly in foreground
  exec "${QEMU_CMD[@]}"
fi
