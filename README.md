# fuel-deploy-onos
fuel-deploy-onos


onos is deployed as an independent nodes. Codes for fuel deploy is rewriten to deploy onos.  

modified files for onos:  
templates/virtual_environment/conf/dea.yaml
templates/virtual_environment/conf/dha.yaml  
templates/virtual_environment/vms/onos.xml  
environments/libvirt_environment.py


Notification:

git clone https://github.com/openstack/fuel-plugin-onos

with parameter -b Kilo, onos service is in a new node. During deployment, you need assign a new node with onos role after selecting onos plugin. Configuraion is places in templates/virtual_environment/conf/new_node. 

whie parameter -b 7.1, onos service is in controllers. During deployment, just assign nodes with controllers and computes after selecting onos plugin. Configuraion is places in templates/virtual_environment/conf/no_node.


deploy examples can be found in deploy.sh in fuel/deploy/
