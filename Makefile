# Default pod makefile distributed with pods version: 12.09.21

default_target: all

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

# Default to a release build.  If you want to enable debugging flags, run
# "make BUILD_TYPE=Debug"
ifeq "$(BUILD_TYPE)" ""
BUILD_TYPE="Release"
endif

all: pod-build/Makefile
	$(MAKE) -C pod-build all install

pod-build/Makefile:
	$(MAKE) configure

.PHONY: configure
configure: boost-pkgconfig
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p pod-build

	# run CMake to generate and configure the build scripts
	@cd pod-build && cmake -DCMAKE_INSTALL_PREFIX=$(BUILD_PREFIX) \
		   -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ..

boost-downloaded-success.touch:
	$(MAKE) boost-fetch
	@echo "\n Fetched Boost 1.54.0 source \n"
	touch boost-downloaded-success.touch

boost-untar-success.touch: boost-downloaded-success.touch
	$(MAKE) boost-untar
	@echo "\n Untared Boost 1.54.0 source \n"
	touch boost-untar-success.touch


boost-fetch:
	@echo "\n Fetching Boost 1.54.0 source \n"

	wget -O boost-1.54.0.tar.gz "http://downloads.sourceforge.net/project/boost/boost/1.54.0/boost_1_54_0.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fboost%2Ffiles%2Fboost%2F1.54.0%2F"


boost-untar:
	@echo "Untaring Boost 1.54.0 source \n"

	@tar xvzf boost-1.54.0.tar.gz


boost-make:
	@echo "\n Making *ALL* Boost libraries (this  takes a while...)\n"

	cd boost_1_54_0/ && ./bootstrap.sh --prefix=$(BUILD_PREFIX) 

	@echo "\n Installing Boost libraries \n"

	cd boost_1_54_0/ && ./b2 install

boost-made-success.touch: boost-untar-success.touch

	$(MAKE) boost-make

	@echo "\n Compiled Boost 1.54.0 libraries (whew!) \n"
	touch boost-made-success.touch

boost-pkgconfig: boost-made-success.touch
	@echo "\n Creating pkg-config file for Boost 1.54.0 \n"

	mkdir -p $(BUILD_PREFIX)/lib/pkgconfig
	find . -maxdepth 1 -iname '*.pc' -exec ./copy-pc.sh {} $(BUILD_PREFIX) boost-1.54.0 \;


clean:
	-if [ -e pod-build/install_manifest.txt ]; then rm -f `cat pod-build/install_manifest.txt`; fi
	-if [ -d pod-build ]; then $(MAKE) -C pod-build clean; rm -rf pod-build; fi
	#rm -f boost-downloaded-success.touch
	#rm -f boost-1.54.0.tar.gz
	rm -f boost-made-success.touch
	find . -maxdepth 1 -iname '*.pc' -exec ./rm-pc.sh {} $(BUILD_PREFIX) boost-1.54.0 \;


# other (custom) targets are passed through to the cmake-generated Makefile 
%::
	$(MAKE) -C pod-build $@
