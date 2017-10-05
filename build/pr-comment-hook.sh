#!/bin/bash

set -e

export COREDNSREPO='github.com/coredns'
export COREDNSPATH='github.com/coredns'

# We receive all json in one giant string in the env var $PAYLOAD.
if [[ -z ${PAYLOAD} ]]; then
    exit 1
fi

# Only trigger on comment creation
action=$(echo ${PAYLOAD} | jq '.action' | tr -d "\n\"")
if [[ "${action}" != "created" ]]; then
  exit 0
fi

# PRs are Issues with a pull_request section.
# If there is no pull_request section, then this is not a PR, we can exit
pull_url=$(echo ${PAYLOAD} | jq '.issue.pull_request.url' | tr -d "\n\"")
if [[ -z ${pull_url} ]]; then
  exit 0
fi

# Get the PR number
export PR=$(echo ${PAYLOAD} | jq '.issue.number' | tr -d "\n\"")

# Create temporary workspace and set GOPATH
workdir=$(mktemp -d)
export GOPATH=$workdir

# Set up a clean up on exit
function finish {
  rm -rf ${workdir}
}
trap finish EXIT

# Get the contents of the comment
body=$(echo ${PAYLOAD} | jq '.comment.body' | tr -d "\n\"")

case "${body}" in
  */integration*)
    # Get ci code
    mkdir -p ${GOPATH}/src/${COREDNSPATH}
    cd ${GOPATH}/src/${COREDNSPATH}
    git clone https://${COREDNSREPO}/ci.git
    cd ci
    # Do integration setup and test
    export K8S_VERSION='v1.7.5'
    make integration
    # TODO post results back to pr
  ;;
  */echo*)

  ;;

esac
