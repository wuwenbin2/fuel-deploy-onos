#!/bin/sh -e
#workbench=/home/onos/wwb/fuel_deploy_0612
workbench=/home/onos/wwb/fuel_deploy_0614
iso=opnfv-2016-06-11_23-59-05.iso
scenaro=os-onos-sfc-ha
exec $workbench/fuel/ci/deploy.sh -b file://$workbench/fuel/deploy/config/ -l devel-pipeline -p huawei-ch -s $scenaro -i file:///root/ISO/$iso  2>&1 | tee out.log
