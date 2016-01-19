#!/bin/bash

# Setup compiler environment variables
function setup_env() {
  export PATH=$install_dir/gcc/bin:$PATH
  export PATH=$install_dir/openmpi/bin:$PATH
  export PATH=$install_dir/hdf5/bin:$PATH
  export PATH=$install_dir/cubit/bin:$PATH
  export PATH=$install_dir/moab/bin:$PATH
  export PATH=$install_dir/geant4/bin:$PATH
  export PATH=$install_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/gmp/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/mpfr/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/mpc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/openmpi/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/hdf5/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/cubit/bin:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/cgm/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/dagmc/lib:$LD_LIBRARY_PATH
}
