#!/usr/bin/env bash
# Boot the Folk live ISO in QEMU with a display, audio, and the Folk web UI
# forwarded to http://localhost:4273 on the host.
#
# usage: ./qemu-run.sh folk-archlinux-*.iso
#
# If your host has no GL (or the guest display stays black), swap
# `virtio-vga-gl` for `virtio-vga` and drop `,gl=on`. Folk still gets a
# Vulkan device inside the VM via lavapipe (CPU rendering).
set -euo pipefail

iso="${1:?usage: $0 <folk-archlinux.iso>}"

accel=tcg
[ -w /dev/kvm ] && accel=kvm

exec qemu-system-x86_64 \
    -machine q35,accel="$accel" -cpu max -smp 4 -m 4096 \
    -device virtio-vga-gl -display gtk,gl=on \
    -device intel-hda -device hda-duplex \
    -nic user,model=virtio-net-pci,hostfwd=tcp::4273-:4273 \
    -cdrom "$iso"
