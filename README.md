## Ethernet LAN on Industrial Ethernet ports

[![](https://images.microbadger.com/badges/image/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://microbadger.com/images/hilschernetpi/netpi-netx-ethernet-lan "Ethernet LAN on Industrial Ethernet ports")
[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://microbadger.com/images/hilschernetpi//netpi-netx-ethernet-lan "Ethernet LAN on Industrial Ethernet ports")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-netx-ethernet-lan.svg)](https://registry.hub.docker.com/u/hilschernetpi/netpi-netx-ethernet-lan/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-netx-ethernet-lan&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-netx-ethernet-lan "Image last updated")&nbsp;

Made for [netPI RTE 3](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Using netPI RTE 3 Industrial Ethernet network ports as standard Ethernet interface

The image provided hereunder deploys a container with installed software turning netPI's Industrial Ethernet ports into a two-ported (switched) standard Ethernet network interface with a single IP address.

Base of this image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell), created user 'root', installed netX driver, network interface daemon and standard Ethernet supporting netX firmware creating an additional network interface named `cifx0`(**c**ommunication **i**nter**f**ace **x**).  The interface can be administered with standard commands such as [ip](https://linux.die.net/man/8/ip) or similar.

#### Container prerequisites

##### Port mapping

For enabling remote login to the container across SSH the container's SSH port 22 needs to be exposed to the host.

##### Privileged mode

The container creates an Ethernet network interface (LAN) from netPI's Industrial network controller netX. Creating a LAN in general needs full access to the Docker host. Also the netX driver needs access to the Docker host GPIO interface to poll for pending incoming Ethernet frames.  Only the privileged mode option lifts the enforced container limitations to allow creation of such a network interface and to access the GPIO interface in a container.

##### Host devices

To grant access to the netX from inside the container the `/dev/spidev0.0` host device needs to be exposed to the container.

To allow the container creating an additional network device for the netX network controller the `/dev/net/tun` host device needs to be expose to the container.

##### Environment Variables

The assignment of the Ethernet network interface's IP address is configured through the following variables

* **IP_ADDRESS** with a value in the format `x.x.x.x` e.g. 192.168.0.1 configures the interface's IP address. A value `dhcp` instead enables the dhcp mode and the interface waits to receive its IP address through a DCHP server.
* **SUBNET_MASK** with a value in the format `x.x.x.x` e.g. 255.255.255.0 configures the interface's subnet mask. It is not necessary to configure in dhcp mode.
* **GATEWAY** with a value in the format `x.x.x.x` e.g. 192.168.0.10 configures the interface's gateway address. It is not necessary to configure in dhcp mode.

#### Getting started

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
*Runtime > Env* | *name* **IP_ADDRESS** -> *value* **e.g.192.168.0.1** | value `dhcp` enables dhcp mode
*Runtime > Env* | *name* **SUBNET_MASK** -> *value* **e.g.255.255.255.0** | not needed in `dhcp` mode
*Runtime > Env* | *name* **GATEWAY** -> *value* **e.g.192.168.0.10** | not needed in `dhcp` mode
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

Pulling the image may take a while (5-10mins). Sometimes it may take too long and a time out is indicated. In this case repeat STEP 4.

#### Accessing

The container starts the SSH server, the netX network interface daemon of `cifx0`, the NetworkManager and the networking server automatically.

Login to the container with an SSH client such as [putty](http://www.putty.org/) using netPI's IP address at your mapped port. Use the credentials `root` as user and `root` as password when asked and you are logged in as user root.

Use a command e.g. `ip addr show` to list all available network interfaces. You will recognize the additional netX network interface named `cifx0` next to the standard Ethernet interface `eth0`. 

Depending on the given environment variables the `cifx0` Ethernet configuration is set by the container's entrypoint script `entrypoint.sh` using the command `ip`. If the variable IP_ADDRESS has not been defined a static ip address 192.168.253.1 at
subnet 255.255.255.0 is configured. 

#### Limitations

The `cifx0` interface DOES NOT support Ethernet package reception of type multicast.

Servicing the `cifx0` interface is only possible in the container it was created. Even if you have started the container in network mode `host`.

Since netX network controller is a single resource a `cifx0` interface can only be created once (in one container) at a time on netPI.

#### Driver, Firmware and Daemon

There are three components necessary to get the `cifx0` recognized as Ethernet interface by the NetworkManager and the networking server.

##### Driver

There is the netX driver in the repository's folder `driver` negotiating the communication between the Raspberry CPU and netX. The driver is installed using the command `dpkg -i netx-docker-pi-drv-x.x.x.deb` and comes preinstalled in the container. The driver communicates across the device `/dev/spidev0.0` with netX and uses the GPIO24 pin to poll for incoming Ethernet frames indicated by netX across this pin. If GPIO24 is not found already created when the driver is started, the driver creates it under `/sys/class/gpio/` itself.

##### Firmware

There is the firmware for netX in the repository's folder `firmware` enabling the netX Ethernet LAN function. The firmware is installed using the command `dpkg -i netx-docker-pi-pns-eth-x.x.x.x.deb` and comes preinstalled in the container. Once an application (Daemon) is starting the driver, the driver checks whether or not netX is loaded with the appropriate firmware. If not the driver then loads the firmware automatically into netX and starts it.

##### Daemon

There is the Deamon in the repository's folder `driver` running as a background process and keeping the `cifx0` Ethernet interface active. The Daemon is available in the repository as source code named `cifx0daemon.c` and comes precompiled in the container at `/opt/cifx0/cifx0daemon` using the gcc compiler with the option `-pthread` since it uses thread child/parent forking. 

The container starts the Daemon by its entrypoint script `/etc/init.d/entrypoint.sh`. You can see the Daemon running using the `ps -e` command as `cifx0daemon` process.

If you kill the `cifx0daemon` process the `cifx0` interface will be removed as well. The Daemon can be restarted at any time using the `/opt/cifx0/cifx0daemon` command.

#### Automated build

The project complies with the scripting based [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build the image output file. Using this method is a precondition for an [automated](https://docs.docker.com/docker-hub/builds/) web based build process on DockerHub platform.

DockerHub web platform is x86 CPU based, but an ARM CPU coded output file is needed for Raspberry systems. This is why the Dockerfile includes the [balena.io](https://balena.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/) steps.

#### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
