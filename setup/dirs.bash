#!/bin/bash

export orig_dir=$PWD
export dist_dir=/mnt/gluster/$USER/dist         # Location where tarballs can be found
export build_dir=/tmp/$USER/build               # Location to perform the build
export install_dir=/tmp/$USER/opt               # Location to install binaries, libraries, etc.
export copy_dir=/mnt/gluster/$USER/tar_install  # Location to place output tarballs
export DATAPATH=/mnt/gluster/$USER/mcnp_data    # Location of MCNP data
