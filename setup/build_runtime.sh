#!/bin/bash

# Get compilers and set up paths
function get_compile() {
  cd $base_dir
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$compile_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$compile_tar"
  else
    echo $compile_tar not found
    exit
  fi
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
  hdf5_tar=hdf5-"$hdf5_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$hdf5_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$hdf5_tar"
  else
    wget https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-"$hdf5_version"/src/"$hdf5_tar"
  fi
  tar -xzvf hdf5-"$hdf5_version".tar.gz
  ln -s hdf5-"$hdf5_version" src
  cd bld
  ../src/configure --enable-shared \
                   --disable-debug \
                   --prefix="$runtime_dir"/hdf5
  make -j $jobs  # 307912 kB mem
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
  cubit_tar=Cubit_LINUX64."$cubit_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$cubit_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$cubit_tar"
  else
    echo $cubit_tar not found
    exit
  fi
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
  make -j $jobs  # 123180 kB mem
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
  make -j $jobs  # 156772 kB mem
  make install
  export PATH="$runtime_dir"/moab/bin:"$PATH"
  export LD_LIBRARY_PATH="$runtime_dir"/moab/lib/:"$LD_LIBRARY_PATH"
  cd $base_dir
}

# Build FLUKA (not working)
function build_fluka() {
  cd $build_dir
  mkdir -p fluka/bld
  cd fluka
  fluka_tar=fluka"$fluka_version"-linux-gfor64bitAA.tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$fluka_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$fluka_tar"
  else
    echo $fluka_tar not found
    exit
  fi
  mkdir fluka
  ln -s fluka src
  tar -xzvf $fluka_tar -C src
  cd src
  export FLUFOR=gfortran
  export FLUPRO=$PWD
  make
  cd $base_dir
}

# Build Geant4
function build_geant4() {
  cd $build_dir
  mkdir -p geant4/bld
  cd geant4
  geant4_tar=geant4."$geant4_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$geant4_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$geant4_tar"
  else
    wget http://geant4.cern.ch/support/source/"$geant4_tar"
  fi
  tar -xzvf $geant4_tar
  ln -s geant4."$geant4_version" src
  cd bld
  cmake ../src -DGEANT4_USE_SYSTEM_EXPAT=OFF \
               -DCMAKE_INSTALL_PREFIX="$runtime_dir"/geant4
  make -j $jobs
  make install
  export PATH="$runtime_dir"/geant4/bin:"$PATH"
  export LD_LIBRARY_PATH="$runtime_dir"/geant4/lib64/:"$LD_LIBRARY_PATH"
  #export GEANT4DIR=$cwd/geant4
  #source $cwd/geant4/bld/geant4make.sh
  cd $base_dir
}

function build_dagmc() {
  cd $build_dir
  mkdir -p dagmc/bld
  cd dagmc
  git clone https://github.com/svalinn/DAGMC -b develop
  ln -s DAGMC src
  build_string=
  if [[ "$@" == "mcnp5" ]]; then
    cd DAGMC/mcnp5
    mcnp5_tar=mcnp5_dist.tgz
    wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mcnp5_tar"
    if [ $? == 0 ]; then
      wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mcnp5_tar"
    else
      echo $mcnp5_tar not found
      exit
    fi
    tar -xzvf $mcnp5_tar Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../../bld
    build_string+=" "-DBUILD_MCNP5=ON
    build_string+=" "-DMCNP5_DATAPATH="$build_dir"/mcnp_data
  fi
  if [[ "$@" == "geant4" ]]; then  # not working
    cd bld
    build_string+=" "-DBUILD_GEANT4=ON
    build_string+=" "-DGEANT4_DIR="$runtime_dir"/geant4
  fi
  if [[ "$@" == "fluka" ]]; then  # not working
    patch "$runtime_dir"/fluka/flutil/rfluka DAGMC/fluka/rfluka.patch
    cd bld
    build_string+=" "-DBUILD_FLUKA=ON
    build_string+=" "-DFLUKA_DIR=$FLUPRO
  fi
  build_string+=" "-DCMAKE_C_COMPILER="$compile_dir"/gcc/bin/gcc
  build_string+=" "-DCMAKE_CXX_COMPILER="$compile_dir"/gcc/bin/g++
  build_string+=" "-DCMAKE_FORTRAN_COMPILER="$compile_dir"/gcc/bin/gfortran
  build_string+=" "-DCMAKE_INSTALL_PREFIX="$runtime_dir"/dagmc
  build_string+=" $build_dir"/dagmc/src
  cmake ../. $build_string
  make -j $jobs
  make install
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
  wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mcnp5_tar"
}

# Software versions
hdf5_version=1.8.16
cubit_version=12.2
cgm_version=12.2
moab_version=4.9.0
fluka_version=2011.2c
geant4_version=10.00.p02

# Parallel jobs
jobs=8

# Compiler tarball
compile_tar=compile.tar.gz

# Username where tarballs are found (/squid/$username)
username=ljjacobson

# Output tarball

# Directory names
copy_dir=$PWD
base_dir=$HOME
compile_dir="$base_dir"/compile
build_dir="$base_dir"/build
runtime_dir="$base_dir"/runtime
mkdir -p $build_dir
mkdir -p $runtime_dir

# Unpack the compiler tarball
get_compile

# Build DAGMC dependencies
build_hdf5
build_cubit
build_cgm
build_moab

# Build physics packages
if [[ "$@" == "fluka" ]]; then
  build_fluka
fi
if [[ "$@" == "geant4" ]]; then
  build_geant4
fi
if [[ "$@" == "mcnp5" ]]; then
  get_mcnp5
fi

# build dagmc
build_dagmc $2 $3 $4

# pack up the runtime
pack_runtime $2 $3 $4

# remove everything except runtime.tar.gz
ls | grep -v runtime.tar.gz | xargs rm -rf
