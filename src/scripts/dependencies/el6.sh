#!/bin/bash -x

# el6.sh
#
# Script to install requirements:
#		libraries
#		compilers
#		kernels
#		drivers
#
# These are all needed to compile submodules in OpenISS
#
# Need to be root when running this script

if [[ "$1" == "--install" ]]; then
	echo "install"

	yum -y clean all
	yum -y clean expire-cache

	# add epel and elrepo repos needed form some packages below
	EL6TYPE=`head -1 /etc/issue | cut -d ' ' -f 1`
	if [[ "$EL6TYPE" == "Scientific" ]];
	then
		yum install -y epel-release elrepo-release
	else
		# Presuming CentOS and RHEL
		# From 'extras'
		yum install -y epel-release
		# From elrepo.org
		rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
		rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
	fi

	# basic install/compile requirements
	yum install -y git
	yum install -y gcc
	yum install -y make cmake
	
	# recent kernel install for the latest USB3 drivers
	#yum --enablerepo=elrepo-kernel install -y kernel-ml-devel-4.8.7-1.el6.elrepo.x86_64
	yum --enablerepo=elrepo-kernel install -y kernel-ml kernel-ml-devel

	# OpenGL
	yum install -y mesa-libGL
	yum install -y mesa-libGL-devel

	# TODO: refactor somehow; to select dynamically from lspci,
	#       then download or dpkg-nvidia from elrepo
	# TODO: this will need to be installed when booted
	VIDEODRIVERSCRIPT=NVIDIA-Linux-x86_64-375.20.run
	VIDEODRIVERPATH=XFree86/Linux-x86_64/375.20/$VIDEODRIVERSCRIPT
	#VIDEODRIVER=XFree86/Linux-x86_64/340.104/NVIDIA-Linux-x86_64-340.104.run
	wget us.download.nvidia.com/$VIDEODRIVERPATH
	sh $VIDEODRIVERSCRIPT
	
	# install python 34 from epel
	yum --enablerepo=epel install -y python34.x86_64

	# packages for OpenGL and libusb
	yum install -y libXmu-devel libXi-devel glut-devel libudev-devel libtool

	# libfreenect2 dependencies
	# libusb, requires libudev-devel, libtool from above
	pushd ../../libfreenect2/depends
		./install_libusb.sh
	popd

	# turbojpeg (libfreenect2)
	yum install -y turbojpeg-devel
	
	# opencv dependencies
	yum groupinstall -y "Development Tools"
	yum install -y gtk+-devel gtk2-devel
	yum install -y pkgconfig.x86_64
	yum install -y python
	yum install -y numpy
	yum install -y libavc1394-devel.x86_64
	yum install -y libavc1394.x86_64

	# libfreenect	
	# also needs libusb, which is installed above, differently, from libfreenect2
	# we link to it in build.sh
	# XXX: OpenNI2 will require cmake3 and gcc 4.8+ from devtoolset-2

        # openFrameworks
        pushd ../../openFrameworks
        	git submodule update --init --recursive
	popd
        # openframeworks dependencies from the provided script
        pushd ../../openFrameworks/scripts/linux/el6
                ./install_codecs.sh
                ./install_dependencies.sh
	popd

	yum install -y gstreamer-devel gstreamer-plugins-base-devel

# XXX: clean up is outdated; need to be careful
elif [[ "$1" == "--cleanup" ]]; then
	echo "cleanup"
	
	rm -f NVIDIA-Linux-x86_64-375.20.run

	#libusb
	cd ../../../libfreenect2/depends/libusb_src
	make distclean
	cd ..
	rm -rf libusb
	rm -rf libusb_src

	#turbojpeg
	yum remove -y turbojpeg
	yum remove -y turbojpeg-devel

	#opencv
	yum remove -y gtk+-devel gtk2-devel
	yum remove -y pkgconfig.x86_64
	#yum remove -y python
	yum remove -y numpy
	yum remove -y libavc1394-devel.x86_64
	yum remove -y libavc1394.x86_64

	#remove packages installed by yum
	yum remove -y libXmu-devel libXi-devel glut-devel libudev-devel gstreamer-devel gstreamer-plugins-base-devel
fi
