export FLAVOR=linux-shared
export NPROC=8

source env/$FLAVOR.sh
source capp-setup.sh
capp load
capp build -j $NPROC
