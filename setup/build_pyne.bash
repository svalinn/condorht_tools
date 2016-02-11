#!/bin/bash

# Build Python
function build_python() {
  name=python
  version=$python_version
  folder=$name-$python_version
  tarball=Python-$version.tgz
  tar_f=Python-$version
  url=https://www.python.org/ftp/python/$version/$tarball

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
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build HDF5
function build_hdf5() {
  name=hdf5
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
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
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build Setuptools
function build_setuptools() {
  name=setuptools
  version=20.0
  folder=$name-$version
  script=ez_setup.py
  url=https://bootstrap.pypa.io/$script

  cd $build_dir
  mkdir -p $folder
  cd $folder
  if [ ! -f $dist_dir/$script ]; then
    wget $url -P $dist_dir
  fi
  cp $dist_dir/$script .
  python $script --user
  cd $build_dir
}

# Build NumPy
function build_numpy() {
  name=numpy
  version=$numpy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/numpy/NumPy/$version/$tarball

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
  setup_string=
  python setup.py $setup_string install --user
  cd $build_dir
}

# Build SciPy
function build_scipy() {
  name=scipy
  version=$scipy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/scipy/scipy/$version/$tarball

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
  setup_string=
  python setup.py $setup_string install --user
  cd $build_dir
}

# Build Cython
function build_cython() {
  name=cython
  version=$cython_version
  folder=$name-$version
  tarball=Cython-$version.tar.gz
  tar_f=Cython-$version
  url=http://cython.org/release/$tarball

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
  setup_string=
  python setup.py $setup_string install --user
  cd $build_dir
}

# Build PyTables
function build_pytables() {
  name=pytables
  version=$pytables_version
  folder=$name-$version
  tarball=tables-$version.tar.gz
  tar_f=tables-$version
  url=http://downloads.sourceforge.net/project/pytables/pytables/$version/$tarball

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
  setup_string=
  setup_string+=" "--hdf5=$install_dir/hdf5
  python setup.py $setup_string install --user
  cd $build_dir
}

# Build MOAB
function build_moab() {
  name=moab
  version=$moab_version
  folder=$name-$version
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
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build PyTAPS
function build_pytaps() {
  name=pytaps
  version=$pytaps_version
  folder=pytaps-$version-moab-$moab_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=master

  cd $build_dir
  mkdir -p $folder
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  ln -s $name bld
  cd $name
  setup_string=
  setup_string+=" "--iMesh-path=$install_dir/moab
  python setup.py $setup_string install --user
  cd $build_dir
}

# Build PyNE
function build_pyne() {
  name=pyne
  version=$pyne_version
  folder=pyne-$version-moab-$moab_version
  repo=https://github.com/ljacobson64/$name                                     #### not main pyne repo
  branch=condor_build

  cd $install_dir
  mkdir -p $folder
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  ln -s $name bld
  cd $name
  setup_string=
  setup_string+=" "-DMOAB_INCLUDE_DIR=$install_dir/moab/include
  setup_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  setup_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  python setup.py $setup_string install --user -j $jobs
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Pack the results tarball
function pack_results() {
  output_tarball=pyne.tar.gz
  cd $install_dir
  tar -czvf $output_tarball `ls --color=never | grep '^python\|^hdf5\|^moab\|^pyne'`
  mv $output_tarball $copy_dir

  output_tarball=pyne_local.tar.gz
  cd $local_dir
  tar -czvf $output_tarball *
  mv $output_tarball $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  cd
  rm -rf $build_dir $install_dir $local_dir
}

function main() {
  # Directory names
  export dist_dir=/mnt/gluster/$USER/dist       # Location where tarballs can be found
  export build_dir=/home/$USER/build            # Location to perform the build
  export install_dir=/home/$USER/opt            # Location to install binaries, libraries, etc.
  export local_dir=/home/$USER/.local           # Location to install python packages
  export copy_dir=/mnt/gluster/$USER            # Location to place output tarball
  rm -rf $build_dir $install_dir
  mkdir -p $dist_dir $build_dir $install_dir $copy_dir

  source ./versions.bash
  source ./common.bash
  set_compile_env
  set_pyne_env
  get_compile
  export jobs=12

  build_python
  build_hdf5
  build_setuptools
  build_numpy
  build_scipy
  build_cython
  build_pytables
  build_moab
  build_pyne

  pack_results
  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
