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
# Let's get rid of existing images...
#
echo ""
echo ""
echo "*** Deleting our 3 Docker images, if they exist"
echo ""
docker rmi res/apache_static
docker rmi res/express_dynamic
docker rmi res/apache_rp
	
#
# ... and rebuild them
#
echo ""
echo ""
echo "*** Rebuilding our 3 Docker images"
echo ""
docker build --tag res/apache_static --file ./docker-images/apache-php-image/Dockerfile ./docker-images/apache-php-image/
docker build --tag res/express_dynamic --file ./docker-images/express-image/Dockerfile ./docker-images/express-image/
docker build --tag res/apache_rp --file ./docker-images/apache-reverse-proxy/Dockerfile ./docker-images/apache-reverse-proxy/

#
# Start static, dynamic apps and reverse proxy 
#
echo ""
echo ""
echo "*** Starting validation..."
echo ""

docker run -d --name apache_static res/apache_static
docker run -d --name express_dynamic res/express_dynamic

# Grab ipaddresses of the two container, store them in a file
# and extract (non-generic..) the addresses from the file
docker inspect apache_static | grep -i ipaddr | tee addr.log
STATIC_IPADDR=$(sed -n 3p addr.log | cut -c 35-44)
STATIC_IPADDR="$STATIC_IPADDR:80"

docker inspect express_dynamic | grep -i ipaddr | tee addr.log
DYNAMIC_IPADDR=$(sed -n 3p addr.log | cut -c 35-44)
DYNAMIC_IPADDR="$DYNAMIC_IPADDR:3000"

docker run -d -e STATIC_APP=$STATIC_IPADDR -e DYNAMIC_APP=$DYNAMIC_IPADDR -p 8080:80 res/apache_rp





