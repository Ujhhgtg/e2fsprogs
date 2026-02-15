#!/usr/bin/bash
export CC=x86_64-unknown-cosmo-cc
export CXX=x86_64-unknown-cosmo-c++

# Clean and Configure
make clean
./configure \
    --disable-tls \
    --disable-nls \
    --disable-backtrace \
    --prefix=/opt/cosmos/x86_64

# 1. Build the supporting libraries first (Required for all binaries)
# Order matters here due to internal dependencies
make -j$(nproc) -C lib/uuid
make -j$(nproc) -C lib/blkid
make -j$(nproc) -C lib/et
make -j$(nproc) -C lib/ss
make -j$(nproc) -C lib/ext2fs
make -j$(nproc) -C lib/e2p
make -j$(nproc) -C lib/support

# 2. Build the specific binaries you need
# mke2fs: To create the partition on the image file
make -j$(nproc) -C misc mke2fs
x86_64-unknown-cosmo-objcopy -S -O binary ./misc/mke2fs mke2fs.com
# debugfs: To modify/add/remove files inside the image without mounting
make -j$(nproc) -C debugfs debugfs
x86_64-unknown-cosmo-objcopy -S -O binary ./debugfs/debugfs debugfs.com

echo "--- Build Complete ---"
echo "mke2fs is at: mke2fs.com"
echo "debugfs is at: debugfs.com"
