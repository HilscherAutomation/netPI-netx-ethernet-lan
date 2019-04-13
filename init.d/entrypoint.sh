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

# create the corresponding Ethernet configuration file 
if [ -z "$IP_ADDRESS" ]
then 
   ip addr add 192.168.253.1/255.255.255.0 broadcast 192.168.253.255 dev cifx0
   ip link set cifx0 up
else 

   if [ "$IP_ADDRESS" == "dhcp" ]
   then
     dhclient cifx0
   else
     IFS=. read -r i1 i2 i3 i4 <<< "$IP_ADDRESS”
     IFS=. read -r m1 m2 m3 m4 <<< "$SUBNET_MASK"
     BROADCAST=$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))
     ip addr add $IP_ADDRESS/$SUBNET_MASK broadcast $BROADCAST dev cifx0
     ip link set cifx0 up
   fi
fi

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
