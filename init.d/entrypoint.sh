#!/bin/bash +e

#check if container is running in privileged mode
ip link add dummy0 type dummy >/dev/null 2>&1
if [[ -z `grep "dummy0" /proc/net/dev` ]]; then
  echo "Container not running in privileged mode. Sure you configured privileged mode? Container stopped."
  exit 143
fi


#check access to SPI netX interface
if [[ ! -e "/dev/spidev0.0" ]]; then
  echo "Container access to /dev/spidev0.0 not possible. Device /dev/spidev0.0 is not mapped. Container stopped."
  exit 143
fi

#check access to network creating interface
if [[ ! -e "/dev/net/tun" ]]; then
  echo "Container access to /dev/net/tun not possible. Device /dev/net/tun is not mapped. Container stopped."
  exit 143
fi


# catch signals as PID 1 in a container
# SIGNAL-handler
term_handler() {

  echo "terminating ssh ..."
  /etc/init.d/ssh stop

  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

#check presence of device spi0.0 and net device register
if [[ -e "/dev/spidev0.0" ]]&& [[ -e "/dev/net/tun" ]]; then

  echo "cifx0 hardware support (TCP/IP over RTE LAN ports) configured." 

  #pre-configure GPIO 24 to serve as interrupt pin between netX chip and BCM CPU
  echo 24 > /sys/class/gpio/export
  echo rising > /sys/class/gpio/gpio24/edge
  echo in > /sys/class/gpio/gpio24/direction
  echo 1 > /sys/class/gpio/gpio24/active_low

  # create netx "cifx0" ethernet network interface 
  /opt/cifx/cifx0daemon

  # bring interface up first of all
  ip link set cifx0 up

else
  echo "cifx0 hardware support (TCP/IP over RTE LAN ports) not configured. Container stopped." 
  exit 143
fi

# run applications in the background
echo "starting ssh ..."
/etc/init.d/ssh start

#check if container is running in bridged mode
if [[ -z `grep "docker0" /proc/net/dev` ]]; then

  echo "Container running in bridged mode. Use environment variables to configuring cifx0 interface."

  # ip address configured as environment variable?
  if [ -z "$IP_ADDRESS" ]
  then
    # set alternative
    IP_ADDRESS="192.168.253.1"
  fi

  # subnet mask configured as environment variable?
  if [ -z "${SUBNET_MASK}" ]
  then
    # set alternative
    SUBNET_MASK="255.255.255.0"
  fi

  if [ "$IP_ADDRESS" == "dhcp" ]
  then
    # set dhcp mode
    dhclient cifx0
    echo "cifx0 configured to dhcp"
  else
    #split given parameters in factors
    IFS=. read -r i1 i2 i3 i4 <<< "$IP_ADDRESS"
    IFS=. read -r m1 m2 m3 m4 <<< "$SUBNET_MASK"

    #calculate the broadcast address
    BROADCAST=$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))

    # set ip address and subnet mask
    ip addr add $IP_ADDRESS/$SUBNET_MASK broadcast $BROADCAST dev cifx0

    echo "cifx0 ip address/subnet mask set to" $IP_ADDRESS"/"$SUBNET_MASK

    #is a gateway set?
    if [ -n "${GATEWAY}" ]
    then
      echo "gateway set to" $GATEWAY

      # flush default routes
      ip route flush dev cifx0

      # make gateway known
      ip route add $GATEWAY dev cifx0

      # set route via gateway
      NETWORK=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))
      ip route add $NETWORK/$SUBNET_MASK via $GATEWAY src $IP_ADDRESS dev cifx0
    fi
  fi
fi

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
