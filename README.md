## TCP/IP over RTE Industrial Ethernet ports

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://microbadger.com/images/hilschernetpi//netpi-netx-ethernet-lan "Ethernet LAN on Industrial Ethernet ports")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://registry.hub.docker.com/r/hilschernetpi/netpi-netx-ethernet-lan/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-netx-ethernet-lan&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-netx-ethernet-lan "Image last updated")&nbsp;

Made for Raspberry Pi 3B architecture based devices and compatibles featuring a netX51 industrial network controller

### Container features

The image provided herunder deploys a container configuring the double RJ45 socket driven by netX to operate as standard LAN interface (single MAC address, switched always) with a device name `cifx0`.

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with installed netX driver, network interface daemon and netX Ethernet LAN firmware creating an additional network interface named `cifx0`(**c**ommunication **i**nter**f**ace **x**).  The interface can be administered with standard commands such as [ip](https://linux.die.net/man/8/ip) or similar.

For lowering the CPU load during LAN communications accross this interface the container configures the GPIO24 as input signal triggering interrupts from the netX to the RPi CPU in the event of pending frames instead of polling for them periodically.

### Container hosts

The container has been successfully tested on the following Docker hosts

* netPI, model RTE 3, product name NIOT-E-NPI3-51-EN-RE
* netIOT Connect, product name NIOT-E-TPI51-EN-RE
* netFIELD Connect, product name NIOT-E-TPI51-EN-RE/NFLD

netPI devices specifically feature a restricted Docker protecting the Docker host system software's integrity by maximum. The restrictions are

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container setup

#### Host network

The container can run either in `host` or in `bridged` network mode. 

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly.

#### Host devices

To grant access to the netX from inside the container the `/dev/spidev0.0` host device needs to be added to the container.

To allow the container creating an additional network device for the netX the `/dev/net/tun` host device needs to be added to the container.

#### Environment variables

##### In `bridge` network mode

The configuration of the LAN interface `cifx0` is done with the following variables

* IP_ADDRESS with a value in the format `x.x.x.x` e.g. 192.168.0.1 configures the interface IP address. A value `dhcp` instead enables the dhcp mode and the interface waits to receive its IP address through a DCHP server.
* SUBNET_MASK with a value in the format `x.x.x.x` e.g. 255.255.255.0 configures the interface subnet mask. Not necessary to configure in dhcp mode.
* GATEWAY with a value in the format `x.x.x.x` e.g. 192.168.0.10 configures the interface gateway address. A gateway is optional. Not necessary to configure in dhcp mode.

If the variable IP_ADDRESS is not configured it defaults to 192.168.253.1 at subnet mask 255.255.255.0.

##### In `host` network mode

If the container runs in `host` network mode the interface is instantiated on the Docker host as a standard LAN interface. This is why the `cifx0` IP settings have to be configured in the Docker host's web UI network setup dialog (as "eth0" interface) and not in the container. Any change on the IP settings needs a container restart to accept the new IP parameters.

### Container deployment

Pulling the image may take 10 minutes.

#### netPI example

STEP 1. Open netPI's web UI in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-netx-ethernet-lan**
*Network > Network* | **host** or **bridged** | use alternatively
*Restart policy* | **always**
*Runtime > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** |
*Runtime > Devices > +add device* | *Host path* **/dev/net/tun** -> *Container path* **/dev/net/tun** |
*Runtime > Env* | *name* **IP_ADDRESS** -> **e.g.192.168.0.1** or **dhcp** | not in `host` mode
*Runtime > Env* | *name* **SUBNET_MASK** -> *value* **e.g.255.255.255.0** | not in `host` mode, in `bridged` mode no need if `dhcp` configured
*Runtime > Env* | *name* **GATEWAY** -> *value* **e.g.192.168.0.10** | not in `host` mode, in `bridged` mode no need if `dhcp` configured
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

#### Docker command line example

`docker run -d --privileged --network=host --restart=always --device=/dev/spidev0.0:/dev/spidev0.0 --device=/dev/net/tun:/dev/net/tun hilschernetpi/netpi-netx-ethernet-lan`

#### Docker compose example

A `docker-compose.yml` file could look like this

    version: "2"

    services:
     nodered:
       image: hilschernetpi/netpi-netx-ethernet-lan
       restart: always
       privileged: true
       network_mode: host
       devices:
         - "/dev/spidev0.0:/dev/spidev0.0"
         - "/dev/net/tun:/dev/net/tun"

#### Container Ethernet frame throughput and limitation

The netX was designed to support all kind of Industrial Networks as device in the first place. Its performance is high when exchanging IO data with a network master across IO buffers. It was not designed to support high performance message oriented exchange of data as used in Ethernet communications. This is why the provided `cifx0` interface is a low to mid-range performer but is still a good compromise if another Ethernet interface is needed.

Measurements have shown that around 700 to 800KByte/s throughput can be reached across `cifx0` only whereas with the RPi's CPU primary Ethernet port `eth0` 10MByte/s can be reached. The reasons are:

* 25MHz SPI clock frequency between netX and RPi CPU only
* User space driver instead of a kernel driver
* 8 messages deep message receive queue only for incoming Ethernet frames
* SPI handshake protocol with additional overhead between netX and RPi during message based communications

The `cifx0` LAN interface will drop Ethernet frames in case its message queue is being overun at high LAN network traffic. The TCP/IP network protocol embeds a recovery procedure for packet loss due to retransmissions. This is why you usually do not recognize a problem when this happens. Single frame communications using non TCP/IP based traffic like the ping command may recognize lost frames.

The `cifx0` LAN interface DOES NOT support Ethernet package reception of type multicast.

The `cifx0` LAN interface DOES NOT support the [promiscuous mode](https://en.wikipedia.org/wiki/Promiscuous_mode) that is a precondition to support bridging the `cifx0` interface with others.

Since netX is a single hardware resource a `cifx0` interface can only be created once at a time on a Docker host.

#### Container Driver, Firmware and Daemon

There are three components necessary to get the `cifx0` recognized as Ethernet interface by the NetworkManager and the networking server.

##### Driver

There is the netX driver in the repository's folder `driver` negotiating the communication between the Raspberry CPU and netX. The driver is installed using the command `dpkg -i netx-docker-pi-drv-x.x.x.deb` and comes preinstalled in the container. The driver communicates across the device `/dev/spidev0.0` with netX and uses the GPIO24 signal as interrupt signal. The GPIO24 is configured to input signal in the container's start script.

##### Firmware

There is the firmware for netX in the repository's folder `firmware` enabling the netX Ethernet LAN function. The firmware is installed using the command `dpkg -i netx-docker-pi-pns-eth-x.x.x.x.deb` and comes preinstalled in the container. Once an application (Daemon) is starting the driver, the driver checks whether or not netX is loaded with the appropriate firmware. If not the driver then loads the firmware automatically into netX and starts it.

##### Daemon

There is the Deamon in the repository's folder `driver` running as a background process and keeping the `cifx0` Ethernet interface active. The Daemon is available in the repository as source code named `cifx0daemon.c` and comes precompiled in the container at `/opt/cifx0/cifx0daemon` using the gcc compiler with the option `-pthread` since it uses thread child/parent forking. 

The container starts the Daemon by its entrypoint script `/etc/init.d/entrypoint.sh`. You can see the Daemon running using the `ps -e` command as `cifx0daemon` process.

If you kill the `cifx0daemon` process the `cifx0` interface will be removed as well. The Daemon can be restarted at any time using the `/opt/cifx0/cifx0daemon` command.

### License

Copyright (c) Hilscher Gesellschaft fuer Systemautomation mbH. All rights reserved.
Licensed under the LISENSE.txt file information stored in the project's source code repository.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com

