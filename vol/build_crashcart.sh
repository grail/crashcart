#!/bin/bash
set -euo pipefail

PACKAGES=${PACKAGES:-}

cd /dev/crashcart/
nix-channel --list | grep nixos-17.09 || nix-channel --add https://nixos.org/channels/nixos-17.09
nix-channel --update
# workaround issue with downloading gnutls via curl
sed -i 's;ftp://ftp.gnutls.org;https://www.gnupg.org/ftp;g' \
    ~/.nix-defexpr/channels/nixos-17.09/pkgs/development/libraries/gnutls/*.nix
rm -f profile
nix-env -p profile -i ${PACKAGES}
rm -f crashcart.img
truncate -s 1G crashcart.img
mkfs.ext3 crashcart.img
mkdir -p out
mount -t ext2 -o loop crashcart.img out
ln -s "$(readlink -f profile)" out/profile
ln -s profile/bin out/bin
ln -s profile/sbin out/sbin
cp .crashcartrc out/
mkdir -p out/store
for deps in $(nix-store -qR profile); do
    cp -a  "${deps#/dev/crashcart/*}" out/store/
done
umount out
# We expect this to return 1
set +e
e2fsck -f crashcart.img
set -e
resize2fs -M crashcart.img
