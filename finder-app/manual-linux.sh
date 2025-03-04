#!/bin/bash
# Script outline to install and build kernel for assignment full-test.
# Author: Siddhant Jajoo

set -e
set -u

export PATH=${PATH}:/home/emil/x-tools/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin
OUTDIR=/tmp/aeld/
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_stable
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Build the kernel
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} virtconfig || make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

# Create the staginf directory for the root filesystem
mkdir -p ${OUTDIR}/rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,home/conf,lib,lib64,conf}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone https://github.com/mirror/busybox
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    make CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# Make and install busybox
make CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
make CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install
sudo chmod u+s ${OUTDIR}/rootfs/bin/busybox

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)

# Extract interpreter and library names
INTERPRETER=$(basename "$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter" | awk -F: '{print $2}' | tr -d '[]' | xargs)")
LIBS=$(${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library" | awk -F: '{print $2}' | tr -d '[]' | xargs)

echo "Interpreter: $INTERPRETER"
echo "Libraries: $LIBS"

# Copy the interpreter
cp "${SYSROOT}/lib/${INTERPRETER}" ${OUTDIR}/rootfs/lib/ || { echo "Failed to copy interpreter ${SYSROOT}/lib/${INTERPRETER}"; exit 1; }

# Add library dependencies to rootfs
echo "Copying shared libraries..."
for lib in $LIBS; do
    if [ -f "${SYSROOT}/lib64/${lib}" ]; then
        cp "${SYSROOT}/lib64/${lib}" ${OUTDIR}/rootfs/lib/
    elif [ -f "${SYSROOT}/lib/${lib}" ]; then
        cp "${SYSROOT}/lib/${lib}" ${OUTDIR}/rootfs/lib/ 
    else
        echo "Searching for ${lib} in ${SYSROOT}..."
        LIB_PATH=$(find "${SYSROOT}" -name "${lib}" | head -n 1)
        cp "${LIB_PATH}" ${OUTDIR}/rootfs/lib/ || { echo "Failed to copy library ${LIB_PATH}"; exit 1; }
    fi
done
cp ${OUTDIR}/rootfs/lib/* ${OUTDIR}/rootfs/lib64/

# Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1

# Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# Copy the finder related scripts and executables to the /home directory on the target rootfs
mkdir -p ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp -r ${FINDER_APP_DIR}/conf/* ${OUTDIR}/rootfs/home/conf/

# Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
sudo sh -c "echo '#!/bin/sh' > init"
sudo sh -c "echo 'mount -t proc none /proc' >> init"
sudo sh -c "echo 'mount -t sysfs none /sys' >> init"
sudo sh -c "echo 'cd /home' >> init"
sudo sh -c "echo 'echo \"Current directory: \$(/bin/pwd)\"' >> init"
sudo sh -c "echo 'ls -l /home/' >> init"
sudo sh -c "echo 'exec /home/autorun-qemu.sh' >> init"
sudo chmod +x init
find . -print0 | cpio -o -H newc --null | gzip > ${OUTDIR}/initramfs.cpio.gz

echo "Script completed successfully!"
