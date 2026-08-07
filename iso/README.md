# Folk tabletop live ISO (Arch Linux)

A bootable x86_64 Arch Linux live ISO with the whole [Folk manual Linux
tabletop
installation](https://github.com/FolkComputer/folk#manual-linux-tabletop-installation)
preloaded:

- every dependency from the Folk README, mapped from Ubuntu apt names to
  Arch packages ([`packages.extra`](packages.extra));
- the Folk source at `/home/folk/folk` with its vendored deps (jimtcl)
  already built;
- the `folk` systemd service (auto-starts on boot), the `folk` user with
  the README's group memberships, the input-device udev rule, and
  passwordless sudo;
- Vulkan drivers for Intel/AMD/NVIDIA(nouveau) GPUs **plus lavapipe**, a CPU
  Vulkan device, so Folk can run inside a plain QEMU VM;
- `archinstall` (standard Arch live tooling), plus a `folk-install-to-disk`
  helper for turning a live boot into a dual-boot install.

Login: user `folk` / password `folk` (root autologin on the console, as
usual for Arch live ISOs). Folk's web UI is on port `4273`.

## Getting the ISO

Every push touching `iso/` builds the ISO on GitHub Actions (workflow
"Build Folk Arch ISO") and boot-tests it in QEMU. Download it from the
workflow run's **Artifacts** → `folk-archlinux-iso`.

To build locally you need an Arch Linux machine (or the `archlinux` Docker
image with `--privileged`), then:

```
sudo ./iso/build.sh        # output lands in iso/out/
```

## Try it in QEMU

Linux (KVM):

```
./iso/qemu-run.sh folk-archlinux-*.iso
```

then open http://localhost:4273 on the host. The script uses virtio GL
graphics; if your host lacks GL, edit it to use plain `virtio-vga`. Folk
falls back to lavapipe (CPU Vulkan) inside the VM — fine for poking
around, slow for real vision workloads. To hand a real webcam to the VM,
add e.g. `-device qemu-xhci -device usb-host,vendorid=0x...,productid=0x...`.

macOS (Intel or Apple Silicon): use [UTM](https://mac.getutm.app/) or
`qemu-system-x86_64 -machine q35 -m 4096 -display cocoa -cdrom folk-archlinux.iso`.
Note this is an **x86_64** ISO — on M1–M4 Macs it runs under emulation,
which works but is slow (see "Apple Silicon / ARM" below).

Windows: use QEMU for Windows, VirtualBox, or Hyper-V — attach the ISO as
a DVD drive and boot. From WSL2, prefer running a Windows-side hypervisor;
WSL itself cannot boot ISOs.

## Write it to a USB stick (or SD card)

The image is a hybrid ISO: the same file works for a DVD burn or raw USB/SD
write. **This erases the target device.**

- **Any OS (easiest):** [balenaEtcher](https://etcher.balena.io/) or
  [Ventoy](https://www.ventoy.net/) (Ventoy lets you keep multiple ISOs on
  one stick).
- **Linux:** `sudo dd if=folk-archlinux.iso of=/dev/sdX bs=4M status=progress oflag=sync`
  (find `sdX` with `lsblk`).
- **macOS:** `diskutil list` to find the disk, `diskutil unmountDisk /dev/diskN`,
  then `sudo dd if=folk-archlinux.iso of=/dev/rdiskN bs=4m`.
- **Windows:** [Rufus](https://rufus.ie/) in "DD mode", or Etcher. From
  WSL, use the Windows tools — WSL can't write raw USB devices reliably.

## Dual-boot install on a laptop

The live ISO doubles as an installer:

1. **Back up first.** Resizing partitions is inherently risky.
2. On Windows machines: disable BitLocker and Fast Startup, and shrink the
   Windows partition from Disk Management to make free space.
3. Boot the USB stick (you may need to disable Secure Boot in firmware —
   the ISO is unsigned, like official Arch media).
4. Run `archinstall` and do a normal guided install into the free space
   (keep the existing EFI partition; the systemd-boot/GRUB menu will offer
   both OSes).
5. Before rebooting, run `folk-install-to-disk /mnt/archinstall` — it
   copies the Folk service/user setup and source into the installed system
   and installs the dependency packages into it. Folk then starts
   automatically on the installed system too.

## Apple Silicon / ARM notes

- This ISO is x86_64: on M-series Macs it boots only under emulation (UTM
  → "Emulate"), not virtualization, so it's slow.
- Bare-metal dual-boot on Apple Silicon is only possible via
  [Asahi Linux](https://asahilinux.org/)'s installer — Apple's boot chain
  cannot boot generic ISOs from USB. There is no official Arch Linux for
  ARM; the [Arch Linux ARM](https://archlinuxarm.org/) project is the
  aarch64 equivalent.
- The gadget2 handheld itself (Orange Pi 5, RK3588S) also doesn't boot
  ISOs — it needs a raw SD/eMMC image with Rockchip U-Boot. That's a
  separate build target from this ISO; see the main README for the current
  (Ubuntu-based) gadget setup.

## Layout

```
iso/
├── build.sh               # assembles releng profile + overlay, runs mkarchiso
├── packages.extra         # Folk deps (apt → pacman mapping)
├── profiledef.append.sh   # ISO name/label + file permissions
├── qemu-run.sh            # convenience QEMU launcher
└── airootfs/              # overlaid onto the live filesystem
    ├── etc/systemd/system/folk.service        # per the Folk README
    ├── etc/systemd/system/folk-init.service   # creates folk user, unpacks source
    ├── etc/udev/rules.d/99-input.rules        # input group/mode rule
    ├── etc/sudoers.d/folk
    └── usr/local/bin/folk-{init,start,install-to-disk}
```
