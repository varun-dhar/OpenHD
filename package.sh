#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

PACKAGE_ARCH=$1
OS=$2
DISTRO=$3
BUILD_TYPE=$4



if [[ "${DISTRO}" == "buster" ]]; then
    PLATFORM_PACKAGES="-d wiringpi -d veye-raspberrypi -d lifepoweredpi -d gstreamer1.0-omx-rpi-config -d gst-rpicamsrc -d openhd-linux-pi -d libjpeg62-turbo"
    PLATFORM_CONFIGS="--config-files /boot/cmdline.txt --config-files /boot/config.txt --config-files /usr/local/share/openhd/joyconfig.txt"
fi

if [[ "${DISTRO}" == "bullseye" ]]; then
    PLATFORM_PACKAGES="-d lifepoweredpi -d gst-rpicamsrc -d openhd-linux-pi -d libjpeg62-turbo"
    PLATFORM_CONFIGS="--config-files /boot/cmdline.txt --config-files /boot/config.txt --config-files /usr/local/share/openhd/joyconfig.txt"
fi

if [[ "${OS}" == "ubuntu" ]] && [[ "${PACKAGE_ARCH}" == "armhf" || "${PACKAGE_ARCH}" == "arm64" ]]; then
    echo "--------------ADDING nvidia-l4t-gstreamer to package list--------------- "
    PLATFORM_PACKAGES="-d nvidia-l4t-gstreamer -d gcc-8 -d g++-8 -d gcc-9 -d g++-9 -d gcc-10 -d g++-10 -d libboost1.74-dev"
    PLATFORM_CONFIGS="--config-files /usr/local/share/openhd/joyconfig.txt"
    echo "--------------install fmt--------------- "
    cd /opt
    wget https://codeload.github.com/fmtlib/fmt/zip/refs/tags/7.1.3
    unzip 7.1.3
    cd fmt*
    mkdir build 
    cd build
    cmake ..
    sudo make install
    sudo apt purge cmake
    sudo snap install cmake --classic
    hash -r
fi

if [ "${BUILD_TYPE}" == "docker" ]; then
    cat << EOF > /etc/resolv.conf
options rotate
options timeout:1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
fi


apt-get install -y apt-transport-https curl || exit 1

apt -y update || exit 1

PACKAGE_NAME=openhd


PKGDIR=/tmp/${PACKAGE_NAME}-installdir
sudo rm -rf ${PKGDIR}/*

./install_dep.sh || exit 1

cd OpenHD

rm -rf build

mkdir build

cd build

cmake ..
make -j4

ls -a

mkdir -p ${PKGDIR}/usr/local/bin || exit 1
mkdir -p ${PKGDIR}/tmp
mkdir -p ${PKGDIR}/settings
mkdir -p ${PKGDIR}/etc/systemd/system

cp OpenHD ${PKGDIR}/usr/local/bin/OpenHD || exit 1
cp ../../openhd.service  ${PKGDIR}/etc/systemd/system/

echo "copied files"
echo ${PKGDIR}

VERSION="2.1-$(date '+%m%d%H%M')"

rm ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb > /dev/null 2>&1

echo $PACKAGE_ARCH
echo $PACKAGE_NAME
echo $VERSION
echo $PKGDIR

fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION//v} -C ${PKGDIR} \
  $PLATFORM_CONFIGS \
  -p ${PACKAGE_NAME}_VERSION_ARCH.deb \
  --after-install ../../after-install.sh \
  --before-install ../../before-install.sh \
  $PLATFORM_PACKAGES \
  -d "libasio-dev >= 1.10" \
  -d "libseek-thermal >= 20201118.1" \
  -d "flirone-driver >= 20200704.3" \
  -d "wifibroadcast >= 20200930.1" \
  -d "openhd-dump1090-mutability >= 20201122.2" \
  -d "gnuplot-nox" \
  -d "hostapd" \
  -d "iw" \
  -d "isc-dhcp-common" \
  -d "pump" \
  -d "dnsmasq" \
  -d "aircrack-ng" \
  -d "ser2net" \
  -d "i2c-tools" \
  -d "dos2unix" \
  -d "fuse" \
  -d "socat" \
  -d "ffmpeg" \
  -d "indent" \
  -d "libv4l-dev" \
  -d "libusb-1.0-0" \
  -d "libpcap-dev" \
  -d "libpng-dev" \
  -d "libnl-3-dev" \
  -d "libnl-genl-3-dev" \
  -d "libsdl2-2.0-0" \
  -d "libsdl1.2debian" \
  -d "libconfig++9v5" \
  -d "libreadline-dev" \
  -d "libjpeg-dev" \
  -d "libsodium-dev" \
  -d "libfontconfig1" \
  -d "libfreetype6" \
  -d "libgles2-mesa-dev" \
  -d "gstreamer1.0-plugins-base" \
  -d "gstreamer1.0-plugins-good" \
  -d "gstreamer1.0-plugins-bad" \
  -d "gstreamer1.0-plugins-ugly" \
  -d "gstreamer1.0-libav" \
  -d "gstreamer1.0-tools" \
  -d "gstreamer1.0-alsa" \
  -d "gstreamer1.0-pulseaudio" || exit 1

cp *.deb ../../

git describe --exact-match HEAD >/dev/null 2>&1

pip install --upgrade cloudsmith-cli
cloudsmith -k $CLOUDSMITH_API_KEY


if [[ "${DISTRO}" == "bullseye" ]]; then
            cloudsmith push deb openhd/openhd-2-1-alpha/raspbian/${DISTRO} ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb
fi

if [[ "${DISTRO}" == "bionic" ]]; then
            cloudsmith push deb openhd/openhd-2-1-alpha/ubuntu/${DISTRO} ${PACKAGE_NAME}_${VERSION}_${PACKAGE_ARCH}.deb
fi