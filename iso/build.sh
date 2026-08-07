#!/usr/bin/env bash
# Build the Folk tabletop live ISO (Arch Linux, x86_64).
#
# Run as root on Arch Linux — natively, or in the archlinux Docker image
# (which needs --privileged for the mounts mkarchiso performs). CI does the
# latter; see .github/workflows/build-folk-iso.yml.
set -euo pipefail

ISO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-${ISO_DIR}/work}"
OUT_DIR="${OUT_DIR:-${ISO_DIR}/out}"
PROFILE_DIR="${WORK_DIR}/profile"
FOLK_REPO="${FOLK_REPO:-https://github.com/FolkComputer/folk.git}"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: must run as root" >&2
    exit 1
fi
if ! command -v pacman >/dev/null; then
    echo "error: needs Arch Linux (pacman not found)" >&2
    exit 1
fi

msg() { printf '\n==> %s\n' "$*"; }

msg "Installing build tools plus Folk's dependencies (needed for the prebuild)"
mapfile -t extra_pkgs < <(grep -vE '^[[:space:]]*(#|$)' "${ISO_DIR}/packages.extra" | awk '{print $1}')
pacman -Syu --noconfirm --needed archiso git "${extra_pkgs[@]}"

msg "Assembling archiso profile (releng + Folk overlay)"
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}" "${OUT_DIR}"
cp -r /usr/share/archiso/configs/releng "${PROFILE_DIR}"

printf '\n# Folk tabletop additions (from iso/packages.extra)\n' >> "${PROFILE_DIR}/packages.x86_64"
printf '%s\n' "${extra_pkgs[@]}" >> "${PROFILE_DIR}/packages.x86_64"

cp -rT "${ISO_DIR}/airootfs" "${PROFILE_DIR}/airootfs"
cat "${ISO_DIR}/profiledef.append.sh" >> "${PROFILE_DIR}/profiledef.sh"

# The installed-system helper needs the package list at runtime.
mkdir -p "${PROFILE_DIR}/airootfs/opt"
printf '%s\n' "${extra_pkgs[@]}" > "${PROFILE_DIR}/airootfs/opt/folk-packages.txt"

# Mirror the kernel/systemd console onto a serial port so headless QEMU runs
# (and the CI boot test) can watch the boot. tty0 is listed last so the
# display stays the primary console on real hardware.
grep -rl 'archisobasedir=' "${PROFILE_DIR}/syslinux" "${PROFILE_DIR}/grub" "${PROFILE_DIR}/efiboot" 2>/dev/null \
    | xargs -r sed -i 's|archisobasedir=|console=ttyS0,115200 console=tty0 archisobasedir=|g'

msg "Cloning Folk and prebuilding its vendored dependencies (make deps)"
git clone --depth 1 "${FOLK_REPO}" "${WORK_DIR}/folk"
if make -C "${WORK_DIR}/folk" deps; then
    touch "${WORK_DIR}/folk/.folk-deps-prebuilt"
else
    echo "warning: 'make deps' failed; the live system will build them on first boot" >&2
fi

# Ship the checkout as a tarball: mkarchiso copies the airootfs overlay
# without preserving file modes, and Folk's build outputs need exec bits.
mkdir -p "${PROFILE_DIR}/airootfs/opt"
tar -C "${WORK_DIR}" -czf "${PROFILE_DIR}/airootfs/opt/folk.tar.gz" folk

msg "Building the ISO with mkarchiso"
mkarchiso -v -w "${WORK_DIR}/archiso" -o "${OUT_DIR}" "${PROFILE_DIR}"

msg "Build finished"
ls -lh "${OUT_DIR}"
