#!/bin/sh

curr_dir=$(pwd)
logfile=$curr_dir/log
num_proc=4

############################# Preparing Environment #########################################

#************* install packages needed for cross-compilation *******************************
echo "[Info] Preparing Environment"
apt-get update >> $logfile 2>&1
apt-get install -y wget git bzip2 unzip vim cmake >> $logfile 2>&1
apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu pkg-config-aarch64-linux-gnu >> $logfile 2>&1
 
#*******************************************************************************************

#**************************Make appropriate directory***************************************
mkdir /opt/ATLAS
#*******************************************************************************************

#*************************Configure Environment variables***********************************
echo "[Info] Setting Environment variables"
echo "export ARMPREFIX=/usr/aarch64-linux-gnu/opencv" >> /etc/environment  
echo "export PKG_CONFIG_PATH=\$ARMPREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH" >> /etc/environment
echo "export PKG_CONFIG_LIBDIR=\$ARMPREFIX/lib:\$PKG_CONFIG_LIBDIR" >> /etc/environment
echo "export CCPREFIX=aarch64-linux-gnu-" >> /etc/environment
echo "export LD_LIBRARY_PATH=\${ARMPREFIX}/lib:${LD_LIBRARY_PATH}" >> /etc/environment
echo "export C_INCLUDE_PATH=\${ARMPREFIX}/include:\${C_INCLUDE_PATH}" >> /etc/environment
echo "export CPLUS_INCLUDE_PATH=${ARMPREFIX}/include:${CPLUS_INCLUDE_PATH}" >> /etc/environment
source /etc/environment
#*******************************************************************************************


############################# Downloading Packages #########################################

#*********************** FFMPEG ************************************************************
echo "[Info] Downloading FFMPEG"
cd /opt/ATLAS
wget --no-check-certificate https://ffmpeg.org/releases/ffmpeg-4.2.1.tar.bz2 >> $logfile 2>&1
tar -xvf ffmpeg-4.2.1.tar.bz2 >> $logfile 2>&1
mv ffmpeg-4.2.1 FFMPEG 

#*******************************************************************************************

#*********************** xvid **************************************************************
echo "[Info] Downloading Xvid"
cd /opt/ATLAS/
wget --no-check-certificate http://downloads.xvid.org/downloads/xvidcore-1.3.3.tar.gz >> $logfile 2>&1
tar -zxvf xvidcore-1.3.3.tar.gz >> $logfile 2>&1

#*******************************************************************************************

#*********************** v4l ***************************************************************
echo "[Info] Downloading v4l"
cd /opt/ATLAS/
wget --no-check-certificate https://linuxtv.org/downloads/v4l-utils/v4l-utils-1.18.0.tar.bz2 >> $logfile 2>&1
tar -xvf v4l-utils-1.18.0.tar.bz2 >> $logfile 2>&1
mv v4l-utils-1.18.0 v4l-utils

#*******************************************************************************************


#*********************** OpenCV ************************************************************
echo "[Info] Downloading OpenCV"
cd /opt/ATLAS
wget --no-check-certificate https://github.com/opencv/opencv/archive/3.4.1.zip -O opencv-3.4.1.zip >> $logfile 2>&1
wget --no-check-certificate https://github.com/opencv/opencv_contrib/archive/3.4.1.zip -O opencv_contrib-3.4.1.zip >> $logfile 2>&1
unzip opencv-3.4.1.zip  >> $logfile 2>&1
unzip opencv_contrib-3.4.1.zip >> $logfile 2>&1
mv opencv-3.4.1 OpenCV
mv opencv_contrib-3.4.1 OpenCV/

#*******************************************************************************************

############################# Compilation & Install #########################################

#*********************** xvid **************************************************************
echo "[Info] Compiling xVid"
cd /opt/ATLAS/xvidcore/build/generic/
./configure --prefix=${ARMPREFIX} --host=aarch64-linux-gnu --disable-assembly >> $logfile 2>&1
make -j$num_proc  >> $logfile 2>&1
make install  >> $logfile 2>&1
#*******************************************************************************************

#*********************** v4l2 **************************************************************
echo "[Info] Compiling v4l"
FILE="$curr_dir/Makefile.am"

if [[ -f "$FILE" ]]; then
    echo "Transferring $FILE to /opt/ATLAS/v4l-utils/utils/media-ctl/"
    cp $FILE /opt/ATLAS/v4l-utils/utils/media-ctl/ 	
fi
cd /opt/ATLAS/v4l-utils/
./bootstrap.sh >> $logfile 2>&1
./configure --prefix=$ARMPREFIX --host=aarch64-linux-gnu --without-jpeg --with-udevdir=$ARMPREFIX/lib/udev >> $logfile 2>&1
make -j$num_proc >> $logfile 2>&1
make install >> $logfile 2>&1
#*******************************************************************************************

#*********************** FFMPEG **************************************************************
echo "[Info] Compiling ffmpeg"
FILE="$curr_dir/configure.sh"
if [[ -f "$FILE" ]]; then
    echo "Transferring $FILE to /opt/ATLAS/FFMPEG/"
    cp $FILE /opt/ATLAS/FFMPEG/ 	
fi
cd /opt/ATLAS/FFMPEG/
bash configure.sh  >> $logfile 2>&1
make -j$num_proc  >> $logfile 2>&1
make install >> $logfile 2>&1
#*******************************************************************************************


############################################################################################
# This is to fix the problem of opencv make not recognizing v4l header files. Apparantly cmake
# looks into only /usr/aarch64-linux-gnu folder for includes, and if it can't find it there,
# then it gives error while running make. To fix it, we will copy all the install files in  
# custom install folder to /usr/aarch64-linux-gnu folder so that there are no errors regarding
# missing libs or include files.
############################################################################################
cp -rf $ARMPREFIX/bin/* /usr/aarch64-linux-gnu/bin/
cp -rf $ARMPREFIX/include/* /usr/aarch64-linux-gnu/include/
cp -rf $ARMPREFIX/lib/* /usr/aarch64-linux-gnu/lib/
cp -rf $ARMPREFIX/sbin /usr/aarch64-linux-gnu/
cp -rf $ARMPREFIX/etc /usr/aarch64-linux-gnu/
############################################################################################



#*********************** OpenCV **************************************************************
echo "[Info] Compiling OpenCV"
mkdir /opt/ATLAS/OpenCV/build
cd /opt/ATLAS/OpenCV/build
cmake -D CMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc \
	-D CMAKE_CXX_COMPILER=/usr/bin/aarch64-linux-gnu-g++ \
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib-3.4.1/modules \
	-D BUILD_NEW_PYTHON_SUPPORT=ON \
	-D BUILD_TIFF=ON \
	-D WITH_CUDA=OFF \
	-D ENABLE_AVX=OFF \
	-D WITH_OPENGL=OFF \
	-D WITH_OPENCL=OFF \
	-D WITH_IPP=OFF \
	-D WITH_TBB=ON \
	-D BUILD_TBB=ON \
	-D WITH_EIGEN=OFF \
	-D WITH_VTK=OFF \
	-D WITH_LIBV4L=ON \
	-D WITH_V4L=ON \
	-D WITH_FFMPEG=ON \
	-D BUILD_TESTS=OFF \
	-D BUILD_PERF_TESTS=OFF \
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=${ARMPREFIX} \
	-D CMAKE_MAKE_PROGRAM=/usr/bin/make \
	-D CMAKE_TOOLCHAIN_FILE=../platforms/linux/aarch64-gnu.toolchain.cmake .. >> $logfile 2>&1
make -j$num_proc  >> $logfile 2>&1
make install >> $logfile 2>&1
#*******************************************************************************************

############################# TAR Packaging  #########################################
echo "[Info] Installation complete, packaging files"
cp -rf /usr/aarch64-linux-gnu/opencv /opt/
tar -czvf $curr_dir/opencv.tar.gz opencv >> $logfile 2>&1
echo "[Info] Success!!"

