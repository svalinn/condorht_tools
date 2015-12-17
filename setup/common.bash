#!/bin/bash

# Get tarball from /mnt/gluster/$USER or the internet
function get_tar() {
  tarball=$1

  if [ -a /mnt/gluster/$USER/$tarball ]; then
    if [ "${tarball: -3}" = "bz2" ]; then
      tar -xjvf /mnt/gluster/$USER/$tarball
    else
      tar -xzvf /mnt/gluster/$USER/$tarball
    fi
    rm -f $tarball
    return
  fi

  shift
  while test ${#} -gt 0; do
    url=$1
    wget --spider $url/$tarball
    if [ $? == 0 ]; then
      wget $url/$tarball
      if [ "${tarball: -3}" = "bz2" ]; then
        tar -xjvf $tarball
      else
        tar -xzvf $tarball
      fi
      rm -f $tarball
      return
    fi
    shift
  done

  echo $tarball not found
  exit
}

# Setup compiler environment variables
function setup_compile_env() {
  export PATH=$compile_dir/gcc/bin:$PATH
  export PATH=$compile_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$compile_dir/gmp/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/mpfr/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/mpc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/openmpi/lib:$LD_LIBRARY_PATH
}

# Setup DAGMC and dependency environment variables
function setup_dagmc_env() {
  export PATH=$dagmc_dir/hdf5/bin:$PATH
  export PATH=$dagmc_dir/cubit/bin:$PATH
  export PATH=$dagmc_dir/moab/bin:$PATH
  export PATH=$dagmc_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/hdf5/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$dagmc_dir/cubit/bin:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$dagmc_dir/cgm/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$dagmc_dir/moab/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$dagmc_dir/dagmc/lib:$LD_LIBRARY_PATH
}
