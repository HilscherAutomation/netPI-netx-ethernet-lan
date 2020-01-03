#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:buster-20191223

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
ENV HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION 1.1.0

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION \
      description="netX based TCP/IP network interface"

#copy files
COPY "./init.d/*" /etc/init.d/ 
COPY "./driver/*" "./driver/includes/" "./firmware/*" /tmp/

#do installation
RUN apt-get update  \
    && apt-get install -y openssh-server build-essential ifupdown isc-dhcp-client \
#do users root and pi    
    && useradd --create-home --shell /bin/bash pi \
    && echo 'root:root' | chpasswd \
    && echo 'pi:raspberry' | chpasswd \
    && adduser pi sudo \
    && mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
#install netX driver and netX ethernet supporting firmware
    && dpkg -i /tmp/netx-docker-pi-drv-2.0.1-r0.deb \
    && dpkg -i /tmp/netx-docker-pi-pns-eth-3.12.0.8.deb \
#compile netX network daemon that creates the cifx0 ethernet interface
    && echo "Irq=/sys/class/gpio/gpio24/value" >> /opt/cifx/plugins/netx-spm/config0 \
    && cp /tmp/*.h /usr/include/cifx \
    && cp /tmp/cifx0daemon.c /opt/cifx/cifx0daemon.c \
    && gcc /opt/cifx/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \
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
