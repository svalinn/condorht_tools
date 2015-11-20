#!/bin/bash

# Get compilers and set up paths
function get_compile() {
  cd $base_dir
  wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$compile_tar"
  tar -xzvf $compile_tar
  export PATH="$compile_dir"/gcc/bin:"$PATH"
  export LD_LIBRARY_PATH="$compile_dir"/gmp/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/mpfr/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/mpc/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib64:"$LD_LIBRARY_PATH"
}

# Build HDF5
function build_hdf5() {
  cd $build_dir
  mkdir -p hdf5/bld
  cd hdf5
  wget https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-"$hdf5_version"/src/hdf5-"$hdf5_version".tar.gz
  tar -xzvf hdf5-"$hdf5_version".tar.gz
  ln -s hdf5-"$hdf5_version" src
  cd bld
  ../src/configure --enable-shared \
                   --disable-debug \
                   --prefix="$runtime_dir"/hdf5
  make -j $jobs  # 307912 kB
  make install
  export PATH="$runtime_dir"/hdf5/bin:$PATH
  export LD_LIBRARY_PATH="$runtime_dir"/hdf5/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CUBIT
function build_cubit() {
  cd $runtime_dir
  mkdir cubit
  cd cubit
  wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$cubit_tar"
  tar -xzvf $cubit_tar
  rm -f $cubit_tar
  export PATH="$runtime_dir"/cubit/bin:$PATH
  export LD_LIBRARY_PATH="$runtime_dir"/cubit/bin:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CGM
function build_cgm() {
  cd $build_dir
  mkdir -p cgm/bld
  cd cgm
  git clone https://bitbucket.org/fathomteam/cgm -b cgm"$cgm_version"
  ln -s cgm src
  cd cgm
  autoreconf -fi
  cd ../bld
  ../src/configure --enable-optimize \
                   --enable-shared \
                   --disable-debug \
                   --with-cubit="$runtime_dir"/cubit \
                   --prefix="$runtime_dir"/cgm
  make -j $jobs  # 123180 kB
  make install
  export LD_LIBRARY_PATH="$runtime_dir"/cgm/lib/:"$LD_LIBRARY_PATH"
  cd $base_dir
}

# Build MOAB
function build_moab() {
  cd $build_dir
  mkdir -p moab/bld
  cd moab
  git clone https://bitbucket.org/fathomteam/moab -b Version"$moab_version"
  ln -s moab src
  cd moab
  autoreconf -fi
  cd ../bld
  ../src/configure --enable-dagmc \
                   --enable-optimize \
                   --enable-shared \
                   --disable-debug \
                   --with-hdf5="$runtime_dir"/hdf5 \
                   --with-cgm="$runtime_dir"/cgm \
                   --prefix="$runtime_dir"/moab
  make -j $jobs  # 156772 kB
  make install
  export PATH="$runtime_dir"/moab/bin:"$PATH"
  export LD_LIBRARY_PATH="$runtime_dir"/moab/lib/:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_dagmc() {
  export cwd=$PWD
  cd runtime
  git clone https://github.com/svalinn/DAGMC
  cd DAGMC
  mkdir bld
  cd bld

  BUILD_STRING="-DCMAKE_C_COMPILER=$cwd/compile/gcc/bin/gcc -DCMAKE_CXX_COMPILER=$cwd/compile/gcc/bin/g++ -DCMAKE_Fortran_COMPILER=$cwd/compile/gcc/bin/gfortran "

  if [ "$1" == "fluka" ] || [ "$2" == "fluka" ] || [ "$3" == "fluka" ]; then
    BUILD_STRING="$BUILD_STRING -DBUILD_FLUKA=ON -DFLUKA_DIR=$FLUPRO"
    # patch rfluka to support dagmc
    patch $cwd/runtime/fluka/flutil/rfluka ../fluka/rfluka.patch
  fi
  if [ "$1" == "geant4" ] || [ "$2" == "geant4" ] || [ "$3" == "geant4" ]; then
    BUILD_STRING="$BUILD_STRING -DBUILD_GEANT4=ON -DGEANT4_DIR=$GEANT4DIR"
  fi
  if [ "$1" == "mcnp5" ] || [ "$2" == "mcnp5" ] || [ "$3" == "mcnp5" ]; then
    BUILD_STRING="$BUILD_STRING -DBUILD_MCNP5=ON"
    cp ../../../mcnp5v16src.tar.gz $cwd/runtime/DAGMC/mcnp5/
    cd $cwd/runtime/DAGMC/mcnp5
    tar -xzvf mcnp5v16src.tar.gz
    patch -p1 < patch/dagmc.patch.5.1.60
    cd ../bld
  fi

  BUILD_STRING="$BUILD_STRING -DCMAKE_INSTALL_PREFIX=$cwd/runtime/DAGMC"
  cmake ../. $BUILD_STRING
  make
  make install
  cd ../../..
}

function build_geant4() {
  cd runtime
  export cwd=$PWD
  wget http://geant4.cern.ch/support/source/geant4.10.00.p02.tar.gz
  tar -xzvf geant4.10.00.p02.tar.gz
  mv geant4.10.00.p02 geant4
  cd geant4
  mkdir bld
  cd bld
  cmake ../. -DGEANT4_USE_SYSTEM_EXPAT=OFF -DCMAKE_INSTALL_PREFIX=$cwd/geant4
  export GEANT4DIR=$cwd/geant4
  export LD_LIBRARY_PATH="$cwd/geant4/lib:$LD_LIBRARY_PATH"
  make
  make install
  source $cwd/geant4/bld/geant4make.sh
  cd ../../..
}

function build_fluka() {
  cd runtime
  cwd=$PWD
  mkdir fluka
  cd fluka
  wget http://proxy.chtc.wisc.edu/SQUID/$USERNAME/fluka2011.2c-linux-gfor64bitAA.tar.gz
  tar -xzvf fluka2011.2c-linux-gfor64bitAA.tar.gz
  echo $PATH
  echo $LD_LIBRARY_PATH
  export FLUFOR=gfortran
  export FLUPRO=$PWD
  make
  cd ../..
}

# pack up the runtime to bring home
pack_runtime() {
  PACK_STRING=""
  PACK_STRING="$PACK_STRING runtime/hdf5 "
  PACK_STRING="$PACK_STRING runtime/moab "
  PACK_STRING="$PACK_STRING runtime/DAGMC "

  if [ "$1" == "fluka" ] || [ "$2" == "fluka" ] || [ "$3" == "fluka" ]; then
    PACK_STRING="$PACK_STRING runtime/fluka "
  fi
  if [ "$1" == "geant4" ] || [ "$2" == "geant4" ] || [ "$3" == "geant4" ]; then
    PACK_STRING="$PACK_STRING runtime/geant4 "
  fi

  echo "Packing up " $PACK_STRING
  tar -pczf runtime.tar.gz $PACK_STRING
}

# get and patch mcnp5
function get_mcnp5() {
  wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mcnp_tar"
}

# Software versions
hdf5_version=1.8.16
cubit_version=12.2
cgm_version=12.2
moab_version=4.9.0

# Parallel jobs
jobs=8

# Tarball names
compile_tar=compile.tar.gz
cubit_tar=Cubit_LINUX64."$cubit_version".tar.gz
mcnp_tar=mcnp5_dist.tgz

# Directory names
base_dir="$PWD"
compile_dir="$base_dir"/compile
build_dir="$base_dir"/build
runtime_dir="$base_dir"/runtime
mkdir -p $build_dir
mkdir -p $runtime_dir

# Unpack the compiler tarball
username=$1
get_compile

# Build DAGMC dependencies
build_hdf5
build_cubit
build_cgm
build_moab

# build dagmc deps if needed
if [ "$2" == "fluka" ] || [ "$3" == "fluka" ] || [ "$4" == "fluka" ]; then
  build_fluka
fi
if [ "$2" == "geant4" ] || [ "$3" == "geant4" ] || [ "$4" == "geant4" ]; then
  build_geant4
fi
if [ "$2" == "mcnp5" ] || [ "$3" == "mcnp5" ] || [ "$4" == "mcnp5" ]; then
  get_mcnp5 $1
fi


# build dagmc
build_dagmc $2 $3 $4

# pack up the runtime
pack_runtime $2 $3 $4

# remove everything except runtime.tar.gz
ls | grep -v runtime.tar.gz | xargs rm -rf
