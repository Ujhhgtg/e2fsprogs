#!/usr/bin/fish

# Check for compilers
for compiler in x86_64-unknown-cosmo-cc x86_64-unknown-cosmo-c++
    if not type -q $compiler
        printf "\n$BOLD$RED""error$NC: compiler not found. check README.md\n"
        exit 1
    end
end

# Set environment variables
set -gx CC x86_64-unknown-cosmo-cc
set -gx CXX x86_64-unknown-cosmo-c++

# UI Styling
set GREEN (set_color green)
set CYAN (set_color cyan)
set YELLOW (set_color yellow)
set RED (set_color red)
set BOLD (set_color -o)
set NC (set_color normal)

set PROJECT_NAME 'e2fsprogs'

# Helper for transient status messages
function log_status
    printf "\r\033[K  $BOLD$YELLOW»$NC %s..." $argv
end

# Helper for permanent success messages
function log_done
    printf "\r\033[K  $BOLD$GREEN✓$NC %s\n" $argv
end

function build_lib
    set -l lib $argv[1]
    log_status "Compiling $lib"
    
    if not make -j(nproc) -C "$lib" >/tmp/build.log 2>&1
        printf "\n$BOLD$RED""error$NC: check /tmp/build.log\n"
        exit 1
    end
    log_done "Library $lib ready"
end

function build_bin
    set -l dir $argv[1]
    set -l target $argv[2]
    log_status "Building $target"
    
    if not make -j(nproc) -C "$dir" "$target" >/tmp/build.log 2>&1
        printf "\n$BOLD$RED""error$NC: check /tmp/build.log\n"
        exit 1
    end
    
    x86_64-unknown-cosmo-objcopy -S -O binary "./$dir/$target" "./dist/$target.com"
    log_done "Binary $target -> dist/$target.com"
end

# --- Execution ---

echo "$BOLD$CYAN== Building $PROJECT_NAME ==$NC"

log_status "Configuring project"
if not ./configure \
    --disable-nls \
    --disable-backtrace \
    --prefix=/opt/cosmos/x86_64 \
    CFLAGS="-O2 -g -Wall" \
    >/tmp/build.log 2>&1
    printf "\n$RED""error$NC: Configuration failed. Check /tmp/build.log\n"
    exit 1
end
log_done "Configuration complete"

mkdir -p ./dist

for lib in lib/uuid lib/blkid lib/et lib/ss lib/ext2fs lib/e2p lib/support
    build_lib "$lib"
end

build_bin misc mke2fs
build_bin debugfs debugfs
build_bin e2fsck e2fsck
build_bin resize resize2fs
build_bin misc tune2fs
build_bin misc mklost+found
build_bin misc e2freefrag
build_bin misc e2image
build_bin misc e2label
build_bin misc chattr
build_bin misc e2undo
build_bin misc dumpe2fs

echo "$BOLD$GREEN** $PROJECT_NAME Built Successfully **$NC"

rm /tmp/build.log
