#!/bin/sh
export CFLAGS="-I${ARMPREFIX}/include"  
export LDFLAGS="-L${ARMPREFIX}/lib"  
 

export FFMPEG_FLAGS=" --target-os=linux --arch=arm64 --enable-shared --enable-pic --disable-static --enable-shared --disable-static --enable-gpl --enable-nonfree --enable-ffmpeg --disable-ffplay --enable-swscale --enable-pthreads --disable-yasm --disable-stripping --enable-libxvid --enable-ffmpeg --prefix=${ARMPREFIX} --cross-prefix=aarch64-linux-gnu-" 

export EXTRA_CFLAGS="-I ${ARMPREFIX}/include"  
export LDFLAGS="-L ${ARMPREFIX}/lib"  

./configure $FFMPEG_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS"
