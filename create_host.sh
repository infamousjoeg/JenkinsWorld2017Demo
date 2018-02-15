#! /bin/bash -e
function main() {
  echo "-----"
  fetch_machine_identity
}

function fetch_machine_identity() {

echo "Hostfactory Token= $(cat /var/jenkins_home/hostfactory)\n"
echo "Hostname= $(hostname)\n"
local status="$(curl -k -i -w '%{http_code}' -X POST -H "Authorization: Token token=\"$(cat /var/jenkins_home/hostfactory)\"" https://docker/api/host_factories/hosts?id=$(hostname))"

echo "Status=\n$status\n"

}

main
