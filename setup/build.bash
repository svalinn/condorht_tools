#!/bin/bash

# 1. Build GMP
function build_gmp() {
  # Names
  name=gmp
  version=$gmp_version
  folder=$name-$version
  tarball=$name-$version.tar.bz2
  tar_f=$name-$version
  url=https://gmplib.org/download/gmp/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xjvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 2. Build MPFR
function build_mpfr() {
  # Names
  name=mpfr
  version=$mpfr_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.mpfr.org/mpfr-current/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 3. Build MPC
function build_mpc() {
  # Names
  name=mpc
  version=$mpc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=ftp://ftp.gnu.org/gnu/mpc/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 4. Build GCC
function build_gcc() {
  # Names
  name=gcc
  version=$gcc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.netgull.com/gcc/releases/gcc-$version/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--with-mpc=$install_dir/mpc
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 5. Build OpenMPI
function build_openmpi() {
  # Names
  name=openmpi
  version=$openmpi_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.open-mpi.org/software/ompi/v1.10/downloads/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 6. Build CMake
function build_cmake() {
  # Names
  name=cmake
  version=$cmake_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.cmake.org/files/v3.4/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 7. Build Python
function build_python() {
  # Names
  name=python
  version=$python_version
  folder=$name-$python_version
  tarball=Python-$version.tgz
  tar_f=Python-$version
  url=https://www.python.org/ftp/python/$version/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 8. Build HDF5
function build_hdf5() {
  # Names
  name=hdf5
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$version/src/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 9. Build Setuptools
function build_setuptools() {
  # Names
  name=setuptools
  version=$setuptools_version
  folder=$name-$version
  tarball=$name-$version.zip
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/s/setuptools/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  unzip $dist_dir/$tarball
  ln -s $tar_f src
  ln -s $tar_f bld
  cd $tar_f

  # Strings
  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py install $setup_string
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 10. Build Cython
function build_cython() {
  # Names
  name=cython
  version=$cython_version
  folder=$name-$version
  tarball=Cython-$version.tar.gz
  tar_f=Cython-$version
  url=http://cython.org/release/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  ln -s $tar_f bld
  cd $tar_f

  # Strings
  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py install $setup_string
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 11. Build NumPy
function build_numpy() {
  # Names
  name=numpy
  version=$numpy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/numpy/NumPy/$version/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  ln -s $tar_f bld
  cd $tar_f

  # Strings
  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py build -j $jobs install $setup_string
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 12. Build SciPy
function build_scipy() {
  # Names
  name=scipy
  version=$scipy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/scipy/scipy/$version/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  ln -s $tar_f bld
  cd $tar_f

  # Strings
  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py build -j $jobs install $setup_string
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 13. Build PyTables
function build_pytables() {
  # Names
  name=pytables
  version=$pytables_version
  folder=$name-$version
  tarball=tables-$version.tar.gz
  tar_f=tables-$version
  url=http://downloads.sourceforge.net/project/pytables/pytables/$version/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  ln -s $tar_f bld
  cd $tar_f

  # Strings
  setup_string=
  setup_string+=" "--hdf5=$install_dir/hdf5
  setup_string+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py install $setup_string
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 14. Build CUBIT
function build_cubit() {
  # Names
  name=cubit
  version=$cubit_version
  folder=$name-$version
  tarball=Cubit_LINUX64.$version.tar.gz

  # Setup
  cd $install_dir
  mkdir $folder
  cd $folder
  
  # Extract
  tar -xzvf $dist_dir/$tarball

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 15. Build CGM
function build_cgm() {
  # Names
  name=cgm
  version=$cgm_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=cgm$version

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld

  # Strings
  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  if [[ "$args" == *" cubit "* ]]; then
    config_string+=" "--with-cubit=$install_dir/cubit
  fi
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 16. Build MOAB
function build_moab() {
  # Names
  name=moab
  version=$moab_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=Version$version

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld

  # Strings
  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$install_dir/hdf5
  if [[ "$args" == *" cgm "* ]]; then
    config_string+=" "--with-cgm=$install_dir/cgm
  fi
  config_string+=" "--prefix=$install_dir/$folder

  # Build
  ../src/configure $config_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 17. Build PyTAPS
function build_pytaps() {
  # Names
  name=pytaps
  version=$pytaps_version
  folder=pytaps-$version-moab-$moab_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=$version

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  ln -s $name bld
  cd $name

  # Strings
  setup_string=
  if [[ "$args" == *" cgm "* ]]; then
    setup_string+=" "--iGeom-path=$install_dir/cgm
  fi
  if [[ "$args" == *" moab "* ]]; then
    setup_string+=" "--iMesh-path=$install_dir/moab
  fi
  setup_string_2=
  setup_string_2+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py $setup_string install $setup_string_2
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 18. Build Geant4
function build_geant4() {
  # Names
  name=geant4
  version=$geant4_version
  folder=$name-$version
  tarball=$name.$version.tar.gz
  tar_f=$name.$version
  url=http://geant4.cern.ch/support/source/$tarball

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld

  # Strings
  cmake_string=
  cmake_string+=" "-DGEANT4_USE_SYSTEM_EXPAT=OFF
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder

  # Build
  cmake ../src $cmake_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 19. Build FLUKA
function build_fluka() {
  # Names
  name=fluka
  version=$fluka_version
  folder=$name-$version
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  # Setup
  cd $install_dir
  mkdir -p $folder/bin
  cd $folder/bin
  tar -xzvf $dist_dir/$tarball
  export FLUPRO=$PWD
  export FLUFOR=gfortran

  # Build
  make
  bash flutil/ldpmqmd

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 20. Build DAGMC
function build_dagmc() {
  # Names
  name=dagmc
  version=$dagmc_version
  folder=$name-$version-cub-$cubit_version-moab-$moab_version
  repo=https://github.com/svalinn/$name
  branch=develop
  mcnp5_tarball=mcnp5_dist.tgz

  # Setup
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  if [[ "$args" == *" mcnp5 "* ]]; then
    cd $name/mcnp5
    tar -xzvf $dist_dir/$mcnp5_tarball Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../..
  fi
  if [[ "$args" == *" fluka "* ]]; then
    if [ ! -x $install_dir/fluka/bin/flutil/rfluka.orig ]; then
      patch -Nb $install_dir/fluka/bin/flutil/rfluka $name/fluka/rfluka.patch
    fi
  fi
  cd bld

  # Strings
  cmake_string=
  if [[ "$args" == *" mcnp5 "* ]]; then
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    if [[ "$args" == *" openmpi "* ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ "$args" == *" geant4 "* ]]; then
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$install_dir/geant4
    cmake_string+=" "-DGEANT4_CMAKE_CONFIG:PATH=$install_dir/geant4/lib64/Geant4-10.0.2
  fi
  if [[ "$args" == *" fluka "* ]]; then
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$install_dir/fluka/bin
  fi
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake_string+=" "$build_dir/$folder/src

  # Build
  cmake ../. $cmake_string
  make -j $jobs
  make install

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# 21. Build PyNE
function build_pyne() {
  # Names
  name=pyne
  version=dev
  folder=pyne-$version-moab-$moab_version
  repo=https://github.com/ljacobson64/$name                                     #### not main pyne repo
  branch=condor_build

  # Setup
  cd $build_dir
  mkdir -p $folder
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  ln -s $name bld
  cd $name

  # Strings
  setup_string=
  if [[ "$args" == *" moab "* ]]; then
    setup_string+=" "-DMOAB_INCLUDE_DIR=$install_dir/moab/include
  fi
  setup_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  setup_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  setup_string_2=
  #setup_string_2+=" "--bootstrap
  setup_string_2+=" "--prefix=$install_dir/$folder

  # Build
  PYTHONPATH_orig=$PYTHONPATH
  PYTHONPATH=$install_dir/$folder/lib/python2.7/site-packages:$PYTHONPATH
  mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  python setup.py $setup_string install $setup_string_2 -j $jobs
  PYTHONPATH=$PYTHONPATH_orig

  # Finalize
  cd $install_dir
  ln -snf $folder $name
  tar -czvf install_$folder.tar.gz $name*
  mv install_$folder.tar.gz $copy_dir
  cd $build_dir
}

# Delete unneeded stuff
function cleanup() {
  cd $orig_dir
  rm -rf $orig_dir/* $build_dir $install_dir
}

function main() {
  export orig_dir=$PWD
  export dist_dir=/mnt/gluster/$USER/dist         # Location where tarballs can be found
  export build_dir=/tmp/$USER/build               # Location to perform the build
  export install_dir=/tmp/$USER/opt               # Location to install binaries, libraries, etc.
  export copy_dir=/mnt/gluster/$USER/tar_install  # Location to place output tarballs
  export DATAPATH=/mnt/gluster/$USER/mcnp_data    # Location of MCNP data
  rm -rf $build_dir $install_dir
  mkdir -p $dist_dir $build_dir $install_dir $copy_dir $DATAPATH

  source ./common.bash
  set_versions
  set_env
  export jobs=12

  build_gmp
  build_mpfr
  build_mpc
  build_gcc
  build_openmpi
  build_cmake
  build_python
  build_hdf5
  build_setuptools
  build_numpy
  build_scipy
  build_cython
  build_pytables
  build_cubit
  build_cgm
  build_moab
  build_pytaps
  build_geant4
  build_fluka
  build_dagmc
  build_pyne

  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
