#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:stretch

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-netx-ethernet-lan" \
      org.label-schema.vcs-ref=$VCS_REF

#enable building ARM container on x86 machinery on the web (comment out next line if not built as automated build on docker hub) 
RUN [ "cross-build-start" ]

#version
ENV HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION 0.9.5

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION \
      description="netX based TCP/IP network interface"

#copy files
COPY "./init.d/*" /etc/init.d/ 
COPY "./driver/*" "./firmware/*" /tmp/

#do installation
RUN apt-get update  \
    && apt-get install -y openssh-server build-essential network-manager ifupdown isc-dhcp-client \
#do users root and pi    
    && useradd --create-home --shell /bin/bash pi \
    && echo 'root:root' | chpasswd \
    && echo 'pi:raspberry' | chpasswd \
    && adduser pi sudo \
    && mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
#install netX driver and netX ethernet supporting firmware
    && dpkg -i /tmp/netx-docker-pi-drv-1.1.3-r1.deb \
    && dpkg -i /tmp/netx-docker-pi-pns-eth-3.12.0.8.deb \
#compile netX network daemon
    && gcc /tmp/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \
#enable automatic interface management
    && sudo sed -i 's/^managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf \
#clean up
    && rm -rf /tmp/* \
    && apt-get remove build-essential \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

#set the entrypoint
ENTRYPOINT ["/etc/init.d/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if not built as automated build on docker hub)
RUN [ "cross-build-end" ]
