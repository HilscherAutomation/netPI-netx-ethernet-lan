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

# create the corresponding Ethernet configuration file 
if [ ! -f /etc/network/interfaces.d/cifx0 ]
   then

   touch /etc/network/interfaces.d/cifx0
   echo "auto cifx0" >> /etc/network/interfaces.d/cifx0

   if [ -z "$IP_ADDRESS" ]
   then 
      echo "iface cifx0 inet static" >> /etc/network/interfaces.d/cifx0
      echo "address 192.168.253.1" >>/etc/network/interfaces.d/cifx0 
      echo "network 255.255.255.0" >>/etc/network/interfaces.d/cifx0 
   else 

      if [ "$IP_ADDRESS" == "dhcp" ]
      then
        echo "allow-hotplug cifx0" >> /etc/network/interfaces.d/cifx0
        echo "iface cifx0 inet dhcp" >>/etc/network/interfaces.d/cifx0 
      else
        echo "iface cifx0 inet static" >> /etc/network/interfaces.d/cifx0
        echo "address" $IP_ADDRESS >>/etc/network/interfaces.d/cifx0 
        echo "network" $SUBNET_MASK >>/etc/network/interfaces.d/cifx0 
        echo "gateway" $GATEWAY >>/etc/network/interfaces.d/cifx0 
      fi
   fi
fi

# create netx "cifx0" ethernet network interface 
/opt/cifx/cifx0daemon

#start the network-manager
/etc/init.d/network-manager start

#stop/start the networking
/etc/init.d/networking stop
/etc/init.d/networking start

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
