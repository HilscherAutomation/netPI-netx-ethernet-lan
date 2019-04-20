#!/bin/bash +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {

  echo "terminating ssh ..."
  /etc/init.d/ssh stop

  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

# run applications in the background
echo "starting ssh ..."
/etc/init.d/ssh start

# create netx "cifx0" ethernet network interface 
/opt/cifx/cifx0daemon

# ip address configured as environment variable?
if [ -z "$IP_ADDRESS" ]
then
  # set alternative
  IP_ADDRESS="192.168.253.1"
fi

# subnet mask configured as environment variable?
if [ -z "$SUBNET_MASK" ]
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
  
  #is a getway set?
  if [ -n $GATEWAY ]
  then
    NETWORK=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))
    ip route add $GATEWAY dev cifx0
    ip route add $NETWORK/$SUBNET_MASK via $GATEWAY dev cifx0
  fi
  
  ip link set cifx0 up
fi


# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
