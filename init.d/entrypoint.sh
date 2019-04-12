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
   ip addr add 192.168.253.1/255.255.255.0 dev cifx0
   ip link set cifx0 up
else 

   if [ "$IP_ADDRESS" == "dhcp" ]
   then
     dhclient cifx0
   else
     ip addr add $IP_ADDRESS/$SUBNET_MASK broadcast $GATEWAY dev cifx0
     ip link set cifx0 up
   fi
fi

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
