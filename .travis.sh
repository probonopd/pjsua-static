#!/bin/bash

# ARM cross-compilation using qemu based on https://github.com/lwhsu/travis-qemu/blob/master/.travis-ci.sh

CHROOT_DIR=/tmp/arm-chroot
MIRROR=http://ftp.us.debian.org/debian
VERSION=jessie
CHROOT_ARCH=armhf

# Debian package dependencies for the host
HOST_DEPENDENCIES="debootstrap qemu-user-static binfmt-support sbuild"

# Debian package dependencies for the chrooted environment
GUEST_DEPENDENCIES="build-essential git m4 sudo python-dev"

function setup_arm_chroot {
    # Host dependencies
    sudo apt-get install -qq -y ${HOST_DEPENDENCIES}

    # Create chrooted environment
    sudo mkdir ${CHROOT_DIR}
    sudo debootstrap --foreign --no-check-gpg --include=build-essential \
        --arch=${CHROOT_ARCH} ${VERSION} ${CHROOT_DIR} ${MIRROR}
    sudo cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/
    sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
    sudo sbuild-createchroot --arch=${CHROOT_ARCH} --foreign --setup-only \
        ${VERSION} ${CHROOT_DIR} ${MIRROR}

    # Create file with environment variables which will be used inside chrooted
    # environment
    echo "export ARCH=${ARCH}" > envvars.sh
    echo "export TRAVIS_BUILD_DIR=${TRAVIS_BUILD_DIR}" >> envvars.sh
    chmod a+x envvars.sh

    # Install dependencies inside chroot
    sudo chroot ${CHROOT_DIR} apt-get update
    sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install \
        -qq -y ${GUEST_DEPENDENCIES}

    # Create build dir and copy travis build files to our chroot environment
    sudo mkdir -p ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}
    sudo rsync -av ${TRAVIS_BUILD_DIR}/ ${CHROOT_DIR}/${TRAVIS_BUILD_DIR}/

    # Indicate chroot environment has been set up
    sudo touch ${CHROOT_DIR}/.chroot_is_done

    # Call ourselves again which will cause tests to run
    sudo chroot ${CHROOT_DIR} bash -c "cd ${TRAVIS_BUILD_DIR} && bash ./.travis.sh"
}

if [ -e "/.chroot_is_done" ]; then
  # We are inside ARM chroot
  echo "Running inside chrooted environment"

  . ./envvars.sh
else
  if [ "${ARCH}" = "arm" ]; then
    # ARM test run, need to set up chrooted environment first
    echo "Setting up chrooted ARM environment"
    setup_arm_chroot
  fi
fi

echo "Running tests"
echo "Environment: $(uname -a)"

sudo apt -y install libasound2-dev libopus-dev python-dev swig # swig3.0

# Use static libopus

# sudo find /usr/lib -name libopus.so -delete

# pjsip apps

VERSION=$(wget -q "https://trac.pjsip.org/repos/browser/pjproject/tags?order=date&desc=1" -O - | grep "View Directory" | cut -d ">" -f 2 | cut -d "<" -f 1 | head -n 1)
wget http://www.pjsip.org/release/$VERSION/pjproject-$VERSION.tar.bz2
tar xf pjproject-*.tar.bz2
cd pjproject-*/
./configure CFLAGS='-O2 -fPIC' --enable-static --disable-libwebrtc --disable-video --disable-libyuv --disable-sdl --disable-ffmpeg --disable-v4l2 --disable-openh264 --prefix=/usr
make dep
make -j4
sudo make install # needed for pjsip-apps/src/swig/python below? 
find pjsip-apps/bin -type f -executable -exec strip {} \;
ldd pjsip-apps/bin/pjsua-x86_64-unknown-linux-gnu
tar cfvj ../pjsip-apps-$VERSION.tar.bz2 pjsip-apps/bin/

# pjsip Python bindings

cd pjsip-apps/src/python
make

file build/lib.*/_pjsua.so
ldd build/lib.*/_pjsua.so
ls -lh build/lib.*/_pjsua.so

find .

cd -

# PJSUA2 Python module

cd pjsip-apps/src/swig/python
sudo python setup.py install --install-layout=deb --root=$(readlink -f .)/dist
find . 

cd - 

cd ..
