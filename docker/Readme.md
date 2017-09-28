Instructions
============
This Docker file serves as a simple way to run Condor jobs but bypassing the need to build & maintain
your own environment, which to be frank is a real pain.

You need to place a tarball in this directory, called fluka.tar.gz which is the current fluka2011xxxx.tar.gz from the Fluka
website

You also need to place a mcnp5.tar.gz tarball in this directory, it should contain the mcnp5 source tree from the "Source" directory
and above, i.e. Source/src/ etc

Then run docker build .