#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail


# set CONFDIR, BRIDGE
DIR="$(dirname `readlink -f $0`)"
CONFDIR=$DIR/templates/virtual_environment/conf/no_node
ISO=/root/ISO/OPNFV-FUEL7_A.iso
PLUGINS="$DIR/plugins"


# create TMPDIR if it doesn't exist
export TMPDIR=$DIR/images
[[ -d $TMPDIR ]] || mkdir -p $TMPDIR

# change permissions down to TMPDIR
chmod a+x $TMPDIR

# start the deployment
echo "Issuing command"
echo "sudo ../ci/deploy.sh -iso $ISO -dea $CONFDIR/dea.yaml -dha $CONFDIR/dha.yaml -p $PLUGINS -s $TMPDIR"
echo "--------------------------------------------------------"

sudo ../ci/deploy.sh -iso $ISO -dea $CONFDIR/dea.yaml -dha $CONFDIR/dha.yaml -p $PLUGINS -s $TMPDIR

echo
echo "--------------------------------------------------------"
echo "Done!"


