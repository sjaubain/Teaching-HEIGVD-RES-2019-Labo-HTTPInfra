<?php
	$dynamic_app_1 = getenv('DYNAMIC_APP_1');
	$dynamic_app_2 = getenv('DYNAMIC_APP_2');
	
	$static_app_1 = getenv('STATIC_APP_1');
	$static_app_2 = getenv('STATIC_APP_2');
?>

<VirtualHost *:80>
	ServerName demo.res.ch
	
	<Proxy "balancer://static_cluster/">
		BalancerMember 'http://<?php print "$static_app_1"?>/'
		BalancerMember 'http://<?php print "$static_app_2"?>/'
		ProxySet lbmethod=byrequests
	</Proxy>
	<Proxy "balancer://dynamic_cluster/">
		BalancerMember 'http://<?php print "$dynamic_app_1"?>'
		BalancerMember 'http://<?php print "$dynamic_app_2"?>'
		ProxySet lbmethod=byrequests
	</Proxy>
	ProxyPass "/api/matrix/" "balancer://dynamic_cluster"
	ProxyPassReverse "/api/matrix/" "balancer://dynamic_cluster"
	
	ProxyPass "/" "balancer://static_cluster/"
	ProxyPassReverse "/" "balancer://static_cluster/"
</VirtualHost>