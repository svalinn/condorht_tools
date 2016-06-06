#!/bin/bash

# Check to see if the installed package tarball already exists
# If it does, get and unpack the tarball
# If not, build the package from source
function ensure_build() {
  name=$1
  eval version=\$"$name"_version
  folder=$name-$version
  if [ -f $copy_dir/install_$folder.tar.gz ]; then
    echo Build found for $name-$version
    cd $install_dir
    tar -xzvf $copy_dir/install_$folder.tar.gz
  else
    echo Building $name-$version ...
    build_$name
  fi
}

# Setup steps before build
function setup_build() {
  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ "$1" == "tar" ]; then
    if [ ! -f $dist_dir/$tarball ]; then
      wget $url -P $dist_dir
    fi
    if [ "${tarball: -7}" == ".tar.gz" ]; then
      tar_string="tar -xzvf"
    elif [ "${tarball: -4}" == ".tgz" ]; then
      tar_string="tar -xzvf"
    elif [ "${tarball: -8}" == ".tar.bz2" ]; then
      tar_string="tar -xjvf"
    elif [ "${tarball: -7}" == ".tar.xz" ]; then
      tar_string=" tar -xJvf"
    elif [ "${tarball: -4}" == ".zip" ]; then
      tar_string="unzip"
    fi
    $tar_string $dist_dir/$tarball
    ln -s $tar_f src
  elif [ "$1" == "repo" ]; then
    git clone $repo -b $branch
    ln -s $name src
  fi
  if [ "$2" == "auto" ]; then
    if [ "$1" == "tar" ]; then
      cd $tar_f
    elif [ "$1" == "repo" ]; then
      cd $name
    fi
    autoreconf -fi
    cd ..
  elif [ "$2" == "python" ]; then
    mkdir -p $install_dir/$folder/lib/python2.7/site-packages
  fi
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir/$folder
}

# Finalize a build
function finalize_build() {
  cd $install_dir
  if [ $make_install_tarballs = true ]; then
    tar -czvf install_$folder.tar.gz $name*
    mv install_$folder.tar.gz $copy_dir
  fi
  cd $build_dir
}

# Build GMP
function build_gmp() {
  name=gmp
  version=$gmp_version
  folder=$name-$version
  tarball=$name-$version.tar.bz2
  tar_f=$name-$version
  url=https://gmplib.org/download/gmp/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MPFR
function build_mpfr() {
  name=mpfr
  version=$mpfr_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.mpfr.org/mpfr-current/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MPC
function build_mpc() {
  name=mpc
  version=$mpc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=ftp://ftp.gnu.org/gnu/mpc/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build GCC
function build_gcc() {
  name=gcc
  version=$gcc_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.netgull.com/gcc/releases/gcc-$version/$tarball

  setup_build tar

  config_string=
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--with-mpc=$install_dir/mpc
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build OpenMPI
function build_openmpi() {
  name=openmpi
  version=$openmpi_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.open-mpi.org/software/ompi/v1.10/downloads/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build CMake
function build_cmake() {
  name=cmake
  version=$cmake_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.cmake.org/files/v3.4/$tarball

  setup_build tar

  config_string=
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build Python
function build_python() {
  name=python
  version=$python_version
  folder=$name-$version
  tarball=Python-$version.tgz
  tar_f=Python-$version
  url=https://www.python.org/ftp/python/$version/$tarball

  setup_build tar

  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build HDF5
function build_hdf5() {
  name=hdf5
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$version/src/$tarball

  setup_build tar

  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build LAPACK
function build_lapack() {
  name=lapack
  version=$lapack_version
  folder=$name-$version
  tarball=$name-$version.tgz
  tar_f=$name-$version
  url=http://www.netlib.org/lapack/$tarball

  setup_build tar

  cmake_string=
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder

  cd bld
  cmake ../src $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build Setuptools
function build_setuptools() {
  name=setuptools
  version=$setuptools_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/s/setuptools/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build Cython
function build_cython() {
  name=cython
  version=$cython_version
  folder=$name-$version
  tarball=Cython-$version.tar.gz
  tar_f=Cython-$version
  url=http://cython.org/release/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build NumPy
function build_numpy() {
  name=numpy
  version=$numpy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/numpy/NumPy/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py build -j $jobs install $setup_string

  finalize_build
}

# Build SciPy
function build_scipy() {
  name=scipy
  version=$scipy_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://downloads.sourceforge.net/project/scipy/scipy/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py build -j $jobs install $setup_string

  finalize_build
}

# Build NumExpr
function build_numexpr() {
  name=numexpr
  version=$numexpr_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/n/numexpr/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build PyTables
function build_pytables() {
  name=pytables
  version=$pytables_version
  folder=$name-$version
  tarball=tables-$version.tar.gz
  tar_f=tables-$version
  url=http://downloads.sourceforge.net/project/pytables/pytables/$version/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--hdf5=$install_dir/hdf5
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build Nose
function build_nose() {
  name=nose
  version=$nose_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=https://pypi.python.org/packages/source/n/nose/$tarball

  setup_build tar python

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd $tar_f
  python setup.py install $setup_string

  finalize_build
}

# Build CUBIT
function build_cubit() {
  name=cubit
  version=$cubit_version
  folder=$name-$version
  tarball=Cubit_LINUX64.$version.tar.gz

  cd $install_dir
  ln -snf $folder $name
  mkdir $folder
  cd $folder
  tar -xzvf $dist_dir/$tarball

  finalize_build
}

# Build CGM
function build_cgm() {
  name=cgm
  version=$cgm_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=cgm$version

  setup_build repo auto

  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  if [[ " ${packages[@]} " =~ " cubit " ]]; then
    config_string+=" "--with-cubit=$install_dir/cubit
  fi
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MOAB
function build_moab() {
  name=moab
  version=$moab_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=Version$version

  setup_build repo auto

  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-fbigeom
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$install_dir/hdf5
  if [[ " ${packages[@]} " =~ " cgm " ]]; then
    config_string+=" "--with-cgm=$install_dir/cgm
    config_string+=" "--enable-irel
  fi
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build MeshKit
function build_meshkit() {
  name=meshkit
  version=$meshkit_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=MeshKitv$version
  if [ "$version" = "master" ]; then branch=master; fi

  setup_build repo auto

  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-igeom=$install_dir/cgm
  config_string+=" "--with-imesh=$install_dir/moab
  config_string+=" "--prefix=$install_dir/$folder

  cd bld
  ../src/configure $config_string
  make -j $jobs
  make install

  finalize_build
}

# Build PyTAPS
function build_pytaps() {
  name=pytaps
  version=$pytaps_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=$version

  setup_build repo python

  setup_string=
  if [[ " ${packages[@]} " =~ " cgm " ]]; then
    setup_string+=" "--iGeom-path=$install_dir/cgm
  fi
  setup_string+=" "--iMesh-path=$install_dir/moab
  setup_string_2=
  setup_string_2+=" "--prefix=$install_dir/$folder

  cd $name
  python setup.py $setup_string install $setup_string_2

  finalize_build
}

# Build MCNP5
function build_mcnp5() {
  # build MCNP5 when we build DAGMC
  :
}

# Build Geant4
function build_geant4() {
  name=geant4
  version=$geant4_version
  folder=$name-$version
  tarball=$name.$version.tar.gz
  tar_f=$name.$version
  url=http://geant4.cern.ch/support/source/$tarball

  setup_build tar

  cmake_string=
  cmake_string+=" "-DGEANT4_USE_SYSTEM_EXPAT=OFF
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/gpp
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder

  cd bld
  cmake ../src $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build FLUKA
function build_fluka() {
  name=fluka
  version=$fluka_version
  folder=$name-$version
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  cd $install_dir
  ln -snf $folder $name
  mkdir -p $folder/bin
  cd $folder/bin
  tar -xzvf $dist_dir/$tarball
  export FLUFOR=gfortran
  export FLUPRO=$PWD

  make
  bash flutil/ldpmqmd

  finalize_build
}

# Build DAGMC
function build_dagmc() {
  name=dagmc
  version=$dagmc_version
  folder=$name-$version
  repo=https://github.com/svalinn/$name
  branch=develop
  mcnp5_tarball=mcnp5_dist.tgz

  setup_build repo

  if [[ " ${packages[@]} " =~ " mcnp5 " ]]; then
    cd $name/mcnp5
    tar -xzvf $dist_dir/$mcnp5_tarball Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../..
  fi
  if [[ " ${packages[@]} " =~ " fluka " ]]; then
    if [ ! -x $install_dir/fluka/bin/flutil/rfluka.orig ]; then
      patch -Nb $install_dir/fluka/bin/flutil/rfluka $name/fluka/rfluka.patch
    fi
  fi

  cmake_string=
  if [[ " ${packages[@]} " =~ " mcnp5 " ]]; then
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    if [[ " ${packages[@]} " =~ " openmpi " ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ " ${packages[@]} " =~ " geant4 " ]]; then
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$install_dir/geant4
    cmake_string+=" "-DGEANT4_CMAKE_CONFIG:PATH=$install_dir/geant4/lib64/Geant4-10.2.0
  fi
  if [[ " ${packages[@]} " =~ " fluka " ]]; then
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$install_dir/fluka/bin
  fi
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/gpp
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake_string+=" "$build_dir/$folder/src

  cd bld
  cmake ../. $cmake_string
  make -j $jobs
  make install

  finalize_build
}

# Build PyNE
function build_pyne() {
  name=pyne
  version=dev
  folder=$name-$version
  repo=https://github.com/pyne/$name
  branch=develop

  setup_build repo python

  setup_string=
  setup_string+=" "-DMOAB_INCLUDE_DIR=$install_dir/moab/include
  setup_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/gpp
  setup_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  setup_string_2=
  #setup_string_2+=" "--bootstrap
  setup_string_2+=" "--prefix=$install_dir/$folder

  cd $name
  python setup.py $setup_string install $setup_string_2 -j $jobs
  nuc_data_make

  finalize_build
}

# Build Boost
function build_boost() {
  name=boost
  version=$boost_version
  folder=$name-$version
  tar_f=$name-$version
  
  tarball=${name}_$version
  tarball=`echo $tarball | sed s/'\.'/_/g`
  untar_f=$tarball
  tarball+=.tar.gz
  
  url=https://sourceforge.net/projects/boost/files/boost/$version/$tarball

  setup_build tar

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder
  
  cd ${tarball:0:12}
  ./bootstrap.sh $setup_string
  ./b2 install 
  #  cp -r $untar_f $install_dir/$folder 

  finalize_build
}


# Build Sigcpp
function build_sigcpp() {
  name=sigc++
  version=$sigcpp_version
  folder=$name-$version
  tar_f=$name-$version
  tarball=lib${name}-$version.tar.xz
  url=https://download.gnome.org/sources/lib$name/${version:0:4}/$tarball

  setup_build tar

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd lib$folder
  ./configure $setup_string
  make -j $jobs
  make install

  finalize_build
}

# Build xml2
function build_xml2() {
  name=xml2
  version=$xml2_version
  folder=$name-$version
  tar_f=$name-$version
  tarball=lib${name}-$version.tar.gz
  url=ftp://xmlsoft.org/libxml2/$tarball

  setup_build tar

  setup_string=
  setup_string+=" "--with-python=no
  setup_string+=" "--prefix=$install_dir/$folder

  cd lib$folder
  ./configure $setup_string
  make -j $jobs
  make install

  finalize_build
}

# Build xmlpp
function build_xmlpp() {
  name=xml++
  version=$xmlpp_version
  folder=$name-$version
  tar_f=$name-$version
  tarball=lib${name}-$version.tar.xz
  url=http://ftp.gnome.org/pub/GNOME/sources/lib$name/${xmlpp_version:0:4}/$tarball

  setup_build tar

  setup_string=
  setup_string+=" "--prefix=$install_dir/$folder

  cd lib$folder
  ./configure $setup_string
  make -j $jobs
  make install

  finalize_build
}
