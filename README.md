## Ethernet LAN on Industrial Ethernet ports

[![](https://images.microbadger.com/badges/image/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://microbadger.com/images/hilschernetpi/netpi-netx-ethernet-lan "Ethernet LAN on Industrial Ethernet ports")
[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://microbadger.com/images/hilschernetpi//netpi-netx-ethernet-lan "Ethernet LAN on Industrial Ethernet ports")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://registry.hub.docker.com/u/hilschernetpi/netpi-netx-ethernet-lan/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-netx-ethernet-lan&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-netx-ethernet-lan "Image last updated")&nbsp;

Made for [netPI RTE 3](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Secured netPI Docker

netPI features a restricted Docker protecting the system software's integrity by maximum. The restrictions are 

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container features

The image provided hereunder deploys a container with installed software turning netPI's Industrial Ethernet ports into a two-ported (switched) standard Ethernet network interface with a single IP address named `cifx0`.

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell), created user 'root', installed netX driver, network interface daemon and standard Ethernet supporting netX firmware creating an additional network interface named `cifx0`(**c**ommunication **i**nter**f**ace **x**).  The interface can be administered with standard commands such as [ip](https://linux.die.net/man/8/ip) or similar.

### Container setup

#### Port mapping

For enabling remote login to the container across SSH the container's SSH port 22 needs to be exposed to the host.

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly.

#### Host devices

To grant access to the netX from inside the container the `/dev/spidev0.0` host device needs to be added to the container.

To allow the container creating an additional network device for the netX network controller the `/dev/net/tun` host device needs to be added to the container.

#### Environment variables

The configuration of the LAN interface `cifx0` is done with the following variables

* IP_ADDRESS with a value in the format `x.x.x.x` e.g. 192.168.0.1 configures the interface IP address. A value `dhcp` instead enables the dhcp mode and the interface waits to receive its IP address through a DCHP server.
* SUBNET_MASK with a value in the format `x.x.x.x` e.g. 255.255.255.0 configures the interface subnet mask. Not necessary to configure in dhcp mode.
* GATEWAY with a value in the format `x.x.x.x` e.g. 192.168.0.10 configures the interface gateway address. A gateway is optional. Not necessary to configure in dhcp mode.

### Container deployment

STEP 1. Open netPI's website in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-netx-ethernet-lan**
*Port mapping* | *host* **22** -> *container* **22** | *host*=any unused
*Restart policy* | **always**
*Runtime > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** |
*Runtime > Devices > +add device* | *Host path* **/dev/net/tun** -> *Container path* **/dev/net/tun** |
*Runtime > Env* | *name* **IP_ADDRESS** -> **e.g.192.168.0.1** or **dhcp** | 
*Runtime > Env* | *name* **SUBNET_MASK** -> *value* **e.g.255.255.255.0** | no need for `dhcp`
*Runtime > Env* | *name* **GATEWAY** -> *value* **e.g.192.168.0.10** | no need for `dhcp`
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

Pulling the image may take a while (5-10mins). Sometimes it may take too long and a time out is indicated. In this case repeat STEP 4.

### Container access

The container starts the SSH server, the netX network interface daemon of `cifx0` and configures it according to the set environment variables. If the variable IP_ADDRESS is not found configured an ip address of 192.168.253.1 at subnet mask 255.255.255.0 is automatically set.

You may optionally login to the container with an SSH client such as [putty](http://www.putty.org/) using netPI's IP address at your mapped port. Use the credentials `root` as user and `root` as password when asked and you are logged in as user root.

Use then a command e.g. `ip addr show` to list all available network interfaces. You will recognize the additional netX network interface named `cifx0` next to the standard Ethernet interface `eth0`. 

### Container limitations

The `cifx0` interface DOES NOT support Ethernet package reception of type multicast.

Servicing the `cifx0` interface is only possible in the container it was created. Even if you have started the container in network mode `host`.

Since netX network controller is a single resource a `cifx0` interface can only be created on netPI once (in one container) at a time.

#### Container Ethernet frame throughput

netPI RTE 3's Industrial network controller netX was designed to support all kind of Industrial Networks as device in the first place. Its performance is high when exchanging IO data from and to a master PLC and any Host application via IO buffers periodically. The controller was not designed to support high performance message oriented exchange of data as used with Ethernet communications. This is why the provided `cifx0` interface is a low to mid-range performer but is still a good compromise to the add another Ethernet interface to netPI on demand.

Measurements have shown that around 1MByte/s throughput can be reached across `cifx0` whereas with netPI's primary Ethernet port `eth0` 10MByte/s can be reached in the middle. The reasons for this is the following:

* 25MHz SPI clock frequency between netX and Raspberry Pi CPU only
* User space driver instead of a kernel driver, but enabling its use in a container
* No interrupt support between netX and Raspberry Pi CPU requiring polling in msecs instead
* 8 messages deep message receive queue only for incoming Ethernet frames
* SPI handshake protocol with additional overhead between netX and Raspberry Pi during message based communications

`cifx0` will drop Ethernet frames in case its message queue is being overun at high traffic. A TCP/IP based protocol embeds a recovery from this state when frames are lost. This is why you usually do not recognize a problem when this happens. Using single frame communications with no additional protocol for data repetition like the ping command could result in lost frames indeed.

#### Container Driver, Firmware and Daemon

There are three components necessary to get the `cifx0` recognized as Ethernet interface by the NetworkManager and the networking server.

##### Driver

There is the netX driver in the repository's folder `driver` negotiating the communication between the Raspberry CPU and netX. The driver is installed using the command `dpkg -i netx-docker-pi-drv-x.x.x.deb` and comes preinstalled in the container. The driver communicates across the device `/dev/spidev0.0` with netX and uses the GPIO24 pin to poll for incoming Ethernet frames indicated by netX across this pin. If GPIO24 is not found already created when the driver is started, the driver creates it under `/sys/class/gpio/` itself.

##### Firmware

There is the firmware for netX in the repository's folder `firmware` enabling the netX Ethernet LAN function. The firmware is installed using the command `dpkg -i netx-docker-pi-pns-eth-x.x.x.x.deb` and comes preinstalled in the container. Once an application (Daemon) is starting the driver, the driver checks whether or not netX is loaded with the appropriate firmware. If not the driver then loads the firmware automatically into netX and starts it.

##### Daemon

There is the Deamon in the repository's folder `driver` running as a background process and keeping the `cifx0` Ethernet interface active. The Daemon is available in the repository as source code named `cifx0daemon.c` and comes precompiled in the container at `/opt/cifx0/cifx0daemon` using the gcc compiler with the option `-pthread` since it uses thread child/parent forking. 

The container starts the Daemon by its entrypoint script `/etc/init.d/entrypoint.sh`. You can see the Daemon running using the `ps -e` command as `cifx0daemon` process.

If you kill the `cifx0daemon` process the `cifx0` interface will be removed as well. The Daemon can be restarted at any time using the `/opt/cifx0/cifx0daemon` command.

### Container tips & tricks

For additional help or information visit the Hilscher Forum at https://forum.hilscher.com/

### Container automated build

The project complies with the scripting based [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build the image output file. Using this method is a precondition for an [automated](https://docs.docker.com/docker-hub/builds/) web based build process on DockerHub platform.

DockerHub web platform is x86 CPU based, but an ARM CPU coded output file is needed for Raspberry Pi systems. This is why the Dockerfile includes the [balena.io](https://balena.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/) steps.

### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com

