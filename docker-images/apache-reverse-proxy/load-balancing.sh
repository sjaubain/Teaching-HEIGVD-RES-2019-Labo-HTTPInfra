#!/bin/bash

#
# This is a bit brutal (and will affect your system if you are running other
# containers than those of the lab)
#
echo ""
echo ""
echo "*** Killing all running containers"
echo ""
docker kill $(docker ps -a -q)
docker rm $(docker ps -a -q)

#
# Let's suppose that our three images still exist
# Start static, dynamic apps and reverse proxy 
# with load balancing
#
echo ""
echo ""
echo "*** Starting validation..."
echo ""

# Run balancer containers
docker run -d --name apache_static_1 res/apache_static
docker run -d --name apache_static_2 res/apache_static

docker run -d --name express_dynamic_1 res/express_dynamic
docker run -d --name express_dynamic_2 res/express_dynamic

# Grab ipaddresses of the containers, store them in a file
# and extract (non-generic..) the addresses from the file
docker inspect apache_static_1 | grep -i ipaddr | tee addr.log
STATIC_IPADDR_1=$(sed -n 3p addr.log | cut -c 35-44)
STATIC_IPADDR_1="$STATIC_IPADDR_1:80"

docker inspect apache_static_2 | grep -i ipaddr | tee addr.log
STATIC_IPADDR_2=$(sed -n 3p addr.log | cut -c 35-44)
STATIC_IPADDR_2="$STATIC_IPADDR_2:80"

docker inspect express_dynamic_1 | grep -i ipaddr | tee addr.log
DYNAMIC_IPADDR_1=$(sed -n 3p addr.log | cut -c 35-44)
DYNAMIC_IPADDR_1="$DYNAMIC_IPADDR_1:3000"

docker inspect express_dynamic_2 | grep -i ipaddr | tee addr.log
DYNAMIC_IPADDR_2=$(sed -n 3p addr.log | cut -c 35-44)
DYNAMIC_IPADDR_2="$DYNAMIC_IPADDR_2:3000"

docker run -d -e STATIC_APP_1=$STATIC_IPADDR_1 -e STATIC_APP_2=$STATIC_IPADDR_2 -e DYNAMIC_APP_1=$DYNAMIC_IPADDR_1 -e DYNAMIC_APP_2=$DYNAMIC_IPADDR_2 -p 8080:80 res/apache_rp





