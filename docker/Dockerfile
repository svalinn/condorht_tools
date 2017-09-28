#
# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# pull the base image
FROM centos:latest

# install
RUN \
    yum update && \ 
    yum install -y epel-release && \
    yum install -y gcc gcc-c++ make openssl-devel
RUN \
    yum install -y cmake curl git htop man unzip vim wget emacs
RUN \ 
    yum install -y hdf5 hdf5-devel gcc-fortran blas-devel lapack-devel && \
    yum install -y expat expat-devel libtool autoconf && \
    yum install -y patch texinfo bison-devel flex-devel && \
    yum install -y dejagnu bison flex
# build a new linker since CENTOS7's is ancient and Fluka needs a newer one
RUN \
    /usr/bin/ld -v && \
    cd /opt/ && \
    git clone git://sourceware.org/git/binutils-gdb.git && \
    cd binutils-gdb && \
    mkdir bld && cd bld && \
    ../configure --prefix=/usr/ && \
    make -j && \
    make install && \
    /usr/bin/ld -v && \
    cd /opt/ && rm -rf binutils-gdb
RUN \
    echo "#!/bin/bash" > /opt/env.sh 
RUN \
    echo "source /opt/env.sh" >> ~/.bashrc
# install geant4
RUN \ 
    cd /opt/ && \ 
    mkdir geant4 && \
    cd geant4 && \
    wget http://geant4.cern.ch/support/source/geant4.10.00.p02.tar.gz && \
    tar -zxf geant4.10.00.p02.tar.gz && \
    cd geant4.10.00.p02 && \
    mkdir bld && \
    cd bld && \
    cmake ../. -DGEANT4_INSTALL_DATA=ON -DUSE_SYSTEM_EXPAT=ON -DCMAKE_INSTALL_PREFIX=/opt/geant4/ && \
    make -j4 && \
    make install && \
    cd .. &&  \
    rm -rf bld geant4.10.00.p02 geant4.10.00.p02.tar.gz
RUN \
    echo "source /opt/geant4/bin/geant4.sh" >> /opt/env.sh
# install moab
RUN \ 
    cd /opt && \
    mkdir moab && \
    git clone https://bitbucket.org/fathomteam/moab && \
    cd moab && \
    git checkout 4.9.2 && \
    autoreconf -fi && \
    mkdir bld && \
    cd bld && \
    ../configure --enable-optimize --enable-shared --enable-dagmc --with-hdf5 --prefix=/opt/moab/ && \
    make -j4 && \ 
    make check && \ 
    make install && \
    cd .. && \ 
    rm -rf bld moab
RUN \
    echo "export LD_LIBRARY_PATH=/opt/moab/lib" >> /opt/env.sh && \
    echo 'export PATH=$PATH:/opt/moab/bin' >> /opt/env.sh 
# install fluka
ADD fluka.tar.gz /opt/fluka/.
RUN \
    cd /opt/fluka && \
    export FLUFOR=gfortran && \
    export FLUPRO=$PWD && \
    make && \
    rm -rf fluka.tar.gz
RUN \
    echo "export FLUFOR=gfortran" >> /opt/env.sh && \
    echo "export FLUPRO=/opt/fluka/" >> /opt/env.sh     
# copy mcnp source
RUN mkdir /opt/mcnp5
ADD mcnp5.tar.gz /opt/mcnp5/.
RUN ls /opt/
RUN cat /opt/env.sh
RUN \
    cd /opt/ && \
    cat /opt/env.sh && \
    source ./env.sh && \
    git clone https://github.com/svalinn/dagmc && \
    cd dagmc && \
    cp -r /opt/mcnp5/Source mcnp/mcnp5/Source && \
    cd mcnp/mcnp5 && \
    patch -p0 < patch/dagmc.patch.5.1.60 && \
    cd /opt/dagmc/ && \
    mkdir bld && \
    export LD_LIBRARY_PATH=/opt/moab/lib:$LD_LIBRARY_PATH && \
    cd bld && \
    cmake .. -DCMAKE_LINKER=/opt/binutils/bin/ld \
             -DBUILD_FLUKA=ON -DFLUKA_DIR=$FLUPRO \
             -DBUILD_MCNP5=ON -DMCNP5_DATAPATH="/made/up" \
	     -DBUILD_GEANT4=ON -DGEANT4_DIR=/opt/geant4 \
	     -DCMAKE_INSTALL_PREFIX=/opt/dagmc && \
    make && \
    make install && \
    rm -rf /opt/mcnp5/Source && \
    rm -rf /opt/dagmc/mcnp/mcnp5/Source && \
    rm -rf /opt/dagmc/bld
# set the DAGMC paths
RUN \
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/dagmc/lib' >> /opt/env.sh && \
    echo 'export PATH=$PATH:/opt/dagmc/bin' >> /opt/env.sh
# source the env file to get right path & ldpath
RUN touch /root/.bashrc
RUN echo 'source /opt/env.sh' >> /root/.bashrc
# Set environment variables.
ENV HOME /root
# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
    