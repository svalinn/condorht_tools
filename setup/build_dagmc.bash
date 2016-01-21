#!/bin/bash

# Build HDF5
function build_hdf5() {
  name=hdf5
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version.tar.gz
  url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$version/src/$tarball

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$install_dir/hdf5/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/hdf5/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build CUBIT
function build_cubit() {
  name=cubit
  version=$cubit_version
  folder=$name-$version
  tarball=Cubit_LINUX64.$version.tar.gz

  cd $install_dir
  mkdir $folder
  cd $folder
  tar -xzvf $dist_dir/$tarball
  export PATH=$install_dir/cubit/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/cubit/bin:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build CGM
function build_cgm() {
  name=cgm
  version=$cgm_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=cgm$version

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-cubit=$install_dir/cubit
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  export LD_LIBRARY_PATH=$install_dir/cgm/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build MOAB
function build_moab() {
  name=moab
  version=$moab_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=Version$version

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$install_dir/hdf5
  if [[ "$args" == *" cubit "* ]]; then
    config_string+=" "--with-cgm=$install_dir/cgm
  fi
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$install_dir/moab/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build Geant4
function build_geant4() {
  name=geant4
  version=$geant4_version
  folder=$name-$version
  tarball=$name.$version.tar.gz
  tar_f=$name.$version
  url=http://geant4.cern.ch/support/source/$tarball

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld
  cmake_string=
  cmake_string+=" "-DGEANT4_USE_SYSTEM_EXPAT=OFF
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake ../src $cmake_string
  make -j $jobs
  make install
  export PATH=$install_dir/geant4/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib64:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build FLUKA
function build_fluka() {
  name=fluka
  version=$fluka_version
  folder=$name-$version
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  cd $install_dir
  mkdir -p $folder/bin
  cd $folder/bin
  tar -xzvf $dist_dir/$tarball
  export FLUPRO=$PWD
  export FLUFOR=gfortran
  make
  bash flutil/ldpmqmd
  export PATH=$install_dir/fluka/bin:$PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build DAGMC
function build_dagmc() {
  name=dagmc
  version=$dagmc_version
  folder=$name-$version-cub-$cubit_version-moab-$moab_version
  repo=https://github.com/svalinn/$name
  branch=develop
  mcnp5_tarball=mcnp5_dist.tgz

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cmake_string=
  if [[ "$args" == *" mcnp5 "* ]]; then
    cd $name/mcnp5
    tar -xzvf $dist_dir/$mcnp5_tarball Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../..
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    if [[ "$args" == *" mpi "* ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ "$args" == *" geant4 "* ]]; then
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$install_dir/geant4
  fi
  if [[ "$args" == *" fluka "* ]]; then
    if [ ! -x $install_dir/fluka/bin/flutil/rfluka.orig ]; then
      patch -N $install_dir/fluka/bin/flutil/rfluka $name/fluka/rfluka.patch
    fi
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$install_dir/fluka/bin
  fi
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake_string+=" "$build_dir/$folder/src
  cd bld
  cmake ../. $cmake_string
  make -j $jobs
  make install
  export PATH=$install_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/dagmc/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir
}

function main() {
  export copy_dir=$PWD                  # Location of tarball to be copied back to submit node
  export base_dir=/mnt/gluster/$USER
  export dist_dir=$base_dir/dist        # Location where software tarballs are found
  export install_dir=$base_dir/opt      # Location to place binaries, libraries, etc.
  export build_dir=$copy_dir/build      # Location to perform builds
  export DATAPATH=$base_dir/mcnp_data   # Location of MCNP data
  mkdir -p $dist_dir $install_dir $build_dir

  source ./versions.bash                # Get software versions
  source ./common.bash                  # Common functions
  set_compile_env                       # Set compiler environment variables
  export jobs=12                        # Parallel jobs

  build_hdf5
  if [[ "$args" == *" cubit "* ]]; then
    build_cubit
    build_cgm
  fi
  build_moab
  if [[ "$args" == *" geant4 "* ]]; then
    build_geant4
  fi
  if [[ "$args" == *" fluka "* ]]; then
    build_fluka
  fi
  build_dagmc

  cleanup                               # Delete unneeded stuff
}

set -e
export args="$@"
export args=" "$args" "

main #1> $copy_dir/_condor_stdout 2> $copy_dir/_condor_stderr
