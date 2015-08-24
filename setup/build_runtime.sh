#!/bin/bash

build_moab() {
cd runtime
export cwd=$PWD
git clone https://bitbucket.org/fathomteam/moab
cd moab
git checkout master
autoreconf -fi
mkdir bld
cd bld
../configure --enable-dagmc --enable-shared --disable-debug --enable-optimize --with-hdf5=$cwd/hdf5 --prefix=$cwd/moab
make 
make install
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$cwd/moab/lib/"
export PATH="$cwd/runtime/moab/bin:$PATH"
cd ..
cd ..
cd ..
}

build_hdf5() {
cd runtime
export cwd=$PWD
wget https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.13/src/hdf5-1.8.13.tar.gz
tar -zxf hdf5-1.8.13.tar.gz
mv hdf5-1.8.13 hdf5
cd hdf5
mkdir bld
cd bld
../configure --enable-shared --disable-debug --enable-optimize --prefix=$cwd/hdf5
make
make install
export LD_LIBRARY_PATH="$cwd/hdf5/lib:$LD_LIBRARY_PATH"
export PATH="$cwd/hdf5/bin:$PATH"
cd ..
cd ..
cd ..
}

build_dagmc() {
cd runtime
export cwd=$PWD
git clone https://github.com/svalinn/DAGMC
cd DAGMC
mkdir bld
cd bld

BUILD_STRING="-DCMAKE_C_COMPILER=$cwd/../compile/gcc/bin/gcc -DCMAKE_CXX_COMPILER=$cwd/../compile/gcc/bin/g++ -DCMAKE_Fortran_COMPILER=$cwd/../compile/gcc/bin/gfortran "

if [ "$1" == "fluka" ] || [ "$2" == "fluka" ] || [ "$3" == "fluka" ] ; then
    BUILD_STRING="$BUILD_STRING -DBUILD_FLUKA=ON -DFLUKA_DIR=$FLUPRO"
    # patch rfluka to support dagmc
    patch $cwd/fluka/flutil/rfluka ../fluka/rfluka.patch
fi
if [ "$1" == "geant4" ] || [ "$2" == "geant4" ] || [ "$3" == "geant4" ] ; then
    BUILD_STRING="$BUILD_STRING -DBUILD_GEANT4=ON -DGEANT4_DIR=$GEANT4DIR"
fi
if [ "$1" == "mcnp5" ] || [ "$2" == "mcnp5" ] || [ "$3" == "mcnp5" ] ; then
    BUILD_STRING="$BUILD_STRING -DBUILD_MCNP5=ON"
fi

echo "BUILD STRING = "$BUILD_STRING

cmake ../. $BUILD_STRING -DCMAKE_INSTALL_PREFIX=$cwd/DAGMC
make
make install
cd ..
cd ..
cd ..
}

build_geant4() {
cd runtime
export cwd=$PWD
wget http://geant4.cern.ch/support/source/geant4.10.00.p02.tar.gz
tar -zxf geant4.10.00.p02.tar.gz
mv geant4.10.00.p02 geant4
cd geant4
mkdir bld
cd bld
cmake ../. -DGEANT4_USE_SYSTEM_EXPAT=OFF -DCMAKE_INSTALL_PREFIX=$cwd/geant4
export GEANT4DIR=$cwd/geant4
export LD_LIBRARY_PATH="$cwd/geant4/lib:$LD_LIBRARY_PATH"
make -j8
make install
source $cwd/geant4/bld/geant4make.sh
cd ..
cd ..
cd ..
}

build_fluka() {
cd runtime
cwd=$PWD
mkdir fluka
cd fluka
wget http://proxy.chtc.wisc.edu/SQUID/$USERNAME/fluka2011.2c-linux-gfor64bitAA.tar.gz
tar -zxf fluka2011.2c-linux-gfor64bitAA.tar.gz
echo $PATH
echo $LD_LIBRARY_PATH
export FLUFOR=gfortran
export FLUPRO=$PWD
make 
cd ..
cd ..
}


# gets the compile env and sets up 
get_compile_env() {
export USERNAME=$1
wget  http://proxy.chtc.wisc.edu/SQUID/$USERNAME/compile.tar.gz 
tar -zxf compile.tar.gz
export LD_LIBRARY_PATH="$PWD/compile/gcc/lib64"
export LD_LIBRARY_PATH="$PWD/compile/gcc/lib:$PWD/compile/mpfr/lib:$PWD/compile/mpc/lib:$PWD/compile/gmp/lib:$LD_LIBRARY_PATH"
export PATH="$PWD/compile/gcc/bin:$PATH"
}

# pack up the runtime to bring home
pack_runtime() {
PACK_STRING=""
PACK_STRING="$PACK_STRING runtime/hdf5 "
PACK_STRING="$PACK_STRING runtime/moab "
PACK_STRING="$PACK_STRING runtime/DAGMC "

if [ "$1" == "fluka" ] || [ "$2" == "fluka" ] || [ "$3" == "fluka" ] ; then
    PACK_STRING="$PACK_STRING runtime/fluka "
fi
if [ "$1" == "geant4" ] || [ "$2" == "geant4" ] || [ "$3" == "geant4" ] ; then
    PACK_STRING="$PACK_STRING runtime/geant4 "
fi
if [ "$1" == "mcnp5" ] || [ "$2" == "mcnp5" ] || [ "$3" == "mcnp5" ] ; then
    PACK_STRING="$PACK_STRING runtime/mcnp5 "
fi

echo "Packing up " $PACK_STRING
tar -pczf runtime.tar.gz $PACK_STRING
}

# first get the compile env
get_compile_env $1

mkdir runtime
# build hdf5
build_hdf5
# build moab
build_moab

# build dagmc deps if needed
if [ "$2" == "fluka" ] || [ "$3" == "fluka" ] || [ "$4" == "fluka" ] ; then
    build_fluka
fi
if [ "$2" == "geant4" ] || [ "$3" == "geant4" ] || [ "$4" == "geant4" ]; then
    build_geant4
fi

# build dagmc
build_dagmc $2 $3 $4

# pack up the runtime
pack_runtime $2 $3 $4

# remove everything except runtime.tar.gz
ls | grep -v runtime.tar.gz | xargs rm -rf
