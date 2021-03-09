CREATE DATABASE IF NOT EXISTS keystone ;
CREATE USER 'keystone-user'@'localhost' IDENTIFIED BY 'keystone-password' ;
GRANT ALL ON keystone.* TO 'keystone-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS heat ;
CREATE USER 'heat-user'@'localhost' IDENTIFIED BY 'heat-password' ;
GRANT ALL ON heat.* TO 'heat-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS glance ;
CREATE USER 'glance-user'@'localhost' IDENTIFIED BY 'glance-password' ;
GRANT ALL ON glance.* TO 'glance-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS horizon ;
CREATE USER 'horizon-user'@'localhost' IDENTIFIED BY 'horizon-password' ;
GRANT ALL ON horizon.* TO 'horizon-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS placement ;
CREATE USER 'placement-user'@'localhost' IDENTIFIED BY 'placement-password' ;
GRANT ALL ON placement.* TO 'placement-user'@'localhost' ;

CREATE USER 'nova-user'@'localhost' IDENTIFIED BY 'nova-password' ;
CREATE DATABASE IF NOT EXISTS nova_api ;
GRANT ALL ON nova_api.* TO 'nova-user'@'localhost' ;
CREATE DATABASE IF NOT EXISTS nova_cell0 ;
GRANT ALL ON nova_cell0.* TO 'nova-user'@'localhost' ;
CREATE DATABASE IF NOT EXISTS nova_cell1 ;
GRANT ALL ON nova_cell1.* TO 'nova-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS neutron ;
CREATE USER 'neutron-user'@'localhost' IDENTIFIED BY 'neutron-password' ;
GRANT ALL ON neutron.* TO 'neutron-user'@'localhost' ;

CREATE DATABASE IF NOT EXISTS cinder ;
CREATE USER 'cinder-user'@'localhost' IDENTIFIED BY 'cinder-password' ;
GRANT ALL ON cinder.* TO 'cinder-user'@'localhost' ;