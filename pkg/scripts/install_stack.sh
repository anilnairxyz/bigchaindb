#!/usr/bin/env bash


set -x
set -o xtrace

# Check for uninitialized variables, a big cause of bugs
NOUNSET=${NOUNSET:-}
if [[ -n "$NOUNSET" ]]; then
    set -o nounset
fi

# Stop if any command fails.
set -e

function usage
{
    cat << EOM

    Usage: $ bash ${0##*/} [-v] [-h]

    Installs the BigchainDB devstack or network.

    ENV[STACK]
        Set STACK environment variable to Either 'devstack' or 'network'.
        Network mimics a production network environment with multiple BDB
        nodes, whereas devstack is useful if you plan on modifying the
        bigchaindb code.

    ENV[GIT_BRANCH]
        To configure bigchaindb repo branch to use set GIT_BRANCH environment
        variable

    -v
        Verbose output from ansible playbooks.

    -h
        Show this help and exit.

EOM
}


ERROR='\033[0;31m' # Red
WARN='\033[1;33m' # Yellow
SUCCESS='\033[0;32m' # Green
NC='\033[0m' # No Color

# GIT_BRANCH
git_branch=""

while getopts "h" opt; do
    case "$opt" in
        h)
            usage
            exit
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done


# STACK is a required variable.
stack=$STACK

if [[ ! $stack ]]; then
    echo "STACK environment variable not defined"
    echo
    usage
    exit 1
fi


git_branch=$GIT_BRANCH


if [[ ! $git_branch ]]; then
    echo "You must specify GIT_BRANCH before running."
    echo
    echo usage
    exit 1
fi

# If there are positional arguments left, something is wrong.
if [[ $1 ]]; then
    echo "Don't understand extra arguments: $*"
    usage
    exit 1
fi

mkdir -p logs
log_file=logs/install-$(date +%Y%m%d-%H%M%S).log
exec > >(tee $log_file) 2>&1
echo "Capturing output to $log_file"
echo "Installation started at $(date '+%Y-%m-%d %H:%M:%S')"

function finish {
    echo "Installation finished at $(date '+%Y-%m-%d %H:%M:%S')"
}
trap finish EXIT

export GIT_BRANCH=$git_branch
echo "Using bigchaindb branch '$GIT_BRANCH'"

if [[ -d .vagrant ]]; then
    echo -e "${ERROR}A .vagrant directory already exists here. If you already tried installing $stack, make sure to vagrant destroy the $stack machine and 'rm -rf .vagrant' before trying to reinstall. If you would like to install a separate $stack, change to a different directory and try running the script again.${NC}"
    exit 1
fi

git clone https://github.com/bigchaindb/bigchaindb.git -b $GIT_BRANCH

if [[ $stack == "devstack" ]]; then # Install devstack
    curl -fOL# https://raw.githubusercontent.com/bigchaindb/bigchaindb/${GIT_BRANCH}/pkg/scripts/Vagrantfile
    vagrant up --provider virtualbox
elif [[ $stack == "network" ]]; then # Install network
    echo -e "${WARN}Network support is not yet available"
    exit
else # Throw error
    echo -e "${ERROR}Unrecognized stack name, must be either devstack or network${NC}"
    exit 1
fi

echo -e "${SUCCESS}Finished installing! You may now log in using 'vagrant ssh'"
