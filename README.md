## Ethernet across Industrial Ethernet ports 

Made for [netPI RTE 3](https://www.netiot.com/netpi/), the Open Edge Connectivity Ecosystem with Industrial Ethernet support

### Using netPI's Industrial Ethernet network ports as standard Ethernet interface

The image provided hereunder deploys a container with installed software that turns netPI's Industrial Ethernet ports into a standard Ethernet network interface.

Base of this image builds a tagged version of [debian:jessie](https://hub.docker.com/r/resin/armv7hf-debian/tags/) with enabled [SSH](https://en.wikipedia.org/wiki/Secure_Shell), created user 'root', installed netX driver, network interface daemon and standard Ethernet supporting netX firmware creating an additional network interface named `cifx0`(**c**ommunication **i**nter**f**ace **x**).  The interface can be administered as usual with commands such as [ip](https://linux.die.net/man/8/ip) or similar.

#### Container prerequisites

##### Port mapping

For enabling remote login to the container across SSH the container's SSH port 22 needs to be exposed to the host.

##### Privileged mode

The container creates an Ethernet network interface (LAN) from netPI's Industrial network controller netX. Creating a LAN needs full access to the host Linux. Only the privileged mode option lifts the enforced container limitations to allow creation of such a network interface.

##### Host devices

To grant access to the netX from inside the container the `/dev/spidev0.0` host device needs to be exposed to the container.

To allow the container creating an additional network device for the netX network controller the `/dev/net/tun` host device needs to be expose to the container.

#### Getting started

##### On netPI

STEP 1. Open netPI's landing page under `https://<netpi's ip address>`.

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under **Containers > Add Container**

* **Image**: `hilschernetpi/netpi-netx-ethernet-lan`

* **Restart policy"** : `always`

* **Port mapping**: `Host "22" (any unused one) -> Container "22"`

* **Runtime > Privileged mode** : `On`

* **Runtime > Devices > add device**: `Host "/dev/spidev0.0" -> Container "/dev/spidev0.0"`

* **Runtime > Devices > add device**: `Host "/dev/net/tun" -> Container "/dev/net/tun"`

STEP 4. Press the button **Actions > Start container**

Pulling the image from Docker Hub may take up to 5 minutes.

#### Accessing

The container starts the SSH service and the netX network interface daemon automatically.

Login to it with an SSH client such as [putty](http://www.putty.org/) using netPI's IP address at your mapped port. Use the credentials `root` as user and `root` as password when asked and you are logged in as user root.

Use a command e.g. `ip add show` to list all available network interfaces. Recognize the additional netX network interface named `cifx0` next to the `eth0`. 

You find the auto configuring cifx0 configuration file in /etc/network/interfaces.d/cifx0. Modify it in accordance to [NetworkConfiguration](https://wiki.debian.org/NetworkConfiguration) to meet your demands. Before restarting the networking afterwards with `/etc/init.d/networking restart` make sure you deleted the existing cifx0 ip address setting with a command e.g. `ip add del x.x.x.x/x dev cifx0`.

#### Driver, Firmware and Daemon

There are three components necessary to get the `cifx0` Ethernet LAN interface up an running. The rest is handled by the standard network manager automatically.

##### Driver

There is the netX driver in the repository's folder `driver` negotiating the communication between the Raspberry CPU and netX. The driver is installed using the command `dpkg -i netx-docker-pi-drv-x.x.x.deb` and comes preinstalled in the container. The driver communicates across the device `/dev/spidev0.0` with netX.

##### Firmware

There is the firmware for netX in the repository's folder `firmware` enabling the netX Ethernet LAN function. The firmware is installed using the command `dpkg -i netx-docker-pi-pns-eth-x.x.x.x.deb` and comes preinstalled in the container. Once an application (Daemon) is starting the driver, the driver checks whether or not netX is loaded with the appropriate firmware. If not the driver then loads the firmware automatically into netX and starts it.

##### Daemon

There is the Deamon in the repository's folder `driver` running as a background process and keeping the `cifx0` Ethernet LAN interface active started once. The Daemon is available as source code named `cifx0daemon.c` and comes precompiled in the container using the gcc compiler with the option `-pthread` since it uses thread child/parent forking. When the container is started the Daemon is automatically started by the start script `entrypoint.sh`. You can see the Daemon active on the system using the `ps -e` command as `cifx0daemon` process.

#### Tags

* **hilscher/netPI-netx-ethernet-lan:latest** - non-versioned latest development output of the master branch. Can run on any netPI RTE 3 system software version.

#### GitHub sources
The image is built from the GitHub project [netPI-netx-ethernet-lan](https://github.com/Hilscher/netPI-netx-ethernet-lan). It complies with the [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build a Docker image [automated](https://docs.docker.com/docker-hub/builds/).

View the license information for the software in the Github project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

To build the container for an ARM CPU on [Docker Hub](https://hub.docker.com/)(x86 based) the Dockerfile uses the method described here [resin.io](https://resin.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/).

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
