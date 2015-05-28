#!/bin/bash

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

function minimal_apt_get_install()
{
  if [[ ! -e /var/lib/apt/lists/lock ]]; then
    sudo apt-get update
  fi
  sudo apt-get install -y --no-install-recommends "$@"
}

sudo echo "deb http://archive.ubuntu.com/ubuntu precise main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
sudo echo "deb http://extras.ubuntu.com/ubuntu precise main" | sudo tee -a /etc/apt/sources.list
sudo echo "deb-src http://extras.ubuntu.com/ubuntu precise main" | sudo tee -a /etc/apt/sources.list

sudo apt-get update && sudo apt-get upgrade -y

minimal_apt_get_install \
  subversion \
  make \
  cmake \
  git \
  gcc-4.8 \
  gfortran-4.8 \
  cpp-4.8 \
  g++-4.8 \
  yasm \
  autoconf \
  automake \
  nasm \
  libtool \
  vim \
  augeas-tools \
  augeas-lenses \
  curl \
  software-properties-common \
  python-software-properties \
  bison \
  wget \
  re2c \
  lemon \
  ruby

DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade

minimal_apt_get_install \
  zlib1g-dev \
  libsndfile1-dev \
  yamdi \
  libx264-dev \
  x264 \
  libgnutls-dev \
  libass-dev \
  libgstreamer-plugins-base1.0-0 \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-good1.0-0 \
  libgstreamer-plugins-good1.0-dev \
  libgstreamer1.0-0 \
  libgstreamer1.0-dev \
  libgstreamer-plugins-bad1.0-0 \
  libgstreamer-plugins-bad1.0-dev \
  libgstreamer-vaapi1.0-0 \
  libgstreamer-vaapi1.0-dev \
  libcrypto++-dev \
  libcrypto++-utils \
  libcrypto++9 \
  libssl-dev \
  libpcre3-dev \
  libpcre++-dev \
  libpcre3 \
  libpcrecpp0 \
  libbz2-dev \
  libcurl4-openssl-dev \
  libxpm-dev \
  libfreetype6-dev \
  libfreetype6 \
  t1lib-bin \
  libt1-dev \
  t1utils \
  libmcrypt4 \
  libmcrypt-dev \
  libtomcrypt-dev \
  libtomcrypt0 \
  mcrypt \
  libxslt1.1 \
  libxslt1-dev \
  libgmp-dev \
  libgmp3-dev \
  libvpx-dev \
  vpx-tools \
  libfaad-dev \
  libfaac-dev \
  libopus-dev \
  opus-tools \
  libjpeg-turbo8 \
  libjpeg-turbo8-dev \
  libjpeg-turbo-progs \
  libturbojpeg \
  libopenjpeg2 \
  libopenjpeg-dev \
  openjpeg-tools \
  libmpeg2-4-dev \
  libmpeg2-4 \
  mp4v2-utils \
  libmp4v2-2 \
  libmp4v2-dev \
  libwebp-dev \
  libwebp5 \
  libwebpdemux1 \
  libwebpmux1 \
  libgsm1-dev \
  libgsmme-dev \
  libmp3lame-dev \
  libopencore-amrnb-dev \
  libopencore-amrwb-dev \
  libopencore-amrnb0 \
  libopencore-amrwb0 \
  libpulse-dev \
  librtmp-dev \
  libschroedinger-1.0-0 \
  libschroedinger-dev \
  libspeex-dev \
  libspeex1 \
  libspeexdsp-dev \
  libspeexdsp1 \
  libtheora-dev \
  libtwolame-dev \
  libvo-aacenc-dev \
  libvo-amrwbenc-dev \
  libvorbis-dev \
  libxvidcore-dev \
  libfdk-aac-dev \
  libfdk-aac0 \
  libfaad2 \
  libfaad-dev \
  faad \
  imagemagick \
  libmagick++-dev \
  libmagickwand5 \
  librsvg2-bin \
  libfftw3-bin \
  libfftw3-dev

#ffmpeg
cd /tmp
sudo git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
sudo ./configure --shlibdir=/usr/lib64 --prefix=/usr --mandir=/usr/share/man --libdir=/usr/lib64 --enable-static \
  --extra-cflags='-fmessage-length=0 -grecord-gcc-switches -fstack-protector -O2 -Wall -D_FORTIFY_SOURCE=2 -funwind-tables -fasynchronous-unwind-tables -g -fPIC -I/usr/include/gsm' \
  --disable-x11grab \
  --enable-gpl \
  --enable-version3 \
  --enable-pthreads \
  --enable-avfilter \
  --enable-libpulse \
  --enable-libvpx \
  --enable-libopus \
  --enable-libass \
  --disable-libx265 \
  --enable-libmp3lame \
  --enable-libvorbis \
  --enable-libtheora \
  --enable-libspeex \
  --enable-libxvid \
  --enable-libx264 \
  --enable-libschroedinger \
  --enable-libgsm \
  --enable-libopencore-amrnb \
  --enable-libopencore-amrwb \
  --enable-postproc \
  --disable-libdc1394 \
  --enable-librtmp \
  --enable-libfreetype \
  --enable-avresample \
  --enable-libtwolame \
  --enable-libvo-aacenc \
  --enable-gnutls \
  --enable-nonfree \
  --enable-libfdk-aac \
  --enable-libfaac \
  --enable-libopenjpeg \
  --enable-gray \
  --enable-libwebp \
&& sudo make -j4 install && sudo make install-data && sudo make clean

minimal_apt_get_install libsox-fmt-all lame mp3val sox madplay twolame flac

minimal_apt_get_install nodejs
