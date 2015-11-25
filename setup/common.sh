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
