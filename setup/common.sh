#!/bin/bash

# Get tarball from SQUID or the internet
function get_tar() {
  tarball=$1
  shift

  while test ${#} -gt 0; do
    url=$1
    if [ "$url" == "squid" ]; then
      url=http://proxy.chtc.wisc.edu/SQUID/$username
    fi
    wget --spider $url/$tarball
    if [ $? == 0 ]; then
      wget $url/$tarball
      return
    fi
    shift
  done

  echo $tarball not found
  exit
}

# Get compilers and set up paths
function get_compile() {
  cd $base_dir
  get_tar $compile_tar squid
  tar -xzvf $compile_tar
  rm -f $compile_tar
  export PATH=$compile_dir/gcc/bin:$PATH
  export PATH=$compile_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$compile_dir/gmp/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/mpfr/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/mpc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/openmpi/lib:$LD_LIBRARY_PATH
}

# Get DAGMC and dependencies and set up paths
function get_dagmc() {
  cd $base_dir
  get_tar $dagmc_tar squid
  tar -xzvf $dagmc_tar
  rm -f $dagmc_tar
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
