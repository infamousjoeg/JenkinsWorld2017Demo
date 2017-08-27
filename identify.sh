#!/bin/bash -e

function main() {
  echo "-----"
  fetch_machine_identity
}

function fetch_machine_identity() {

  ########### CHANGE VARIABLES BELOW ############
  local baseurl='https://ubuntu01'
  local hostid='jenkins/masters/master01'
  local token=$(cat src/hftoken.txt | tr -d "\n")
  local cert='~/conjur-cyberarkdemo.pem'
  ###############################################

  echo 'Fetching machine identity from Conjur'

  local status=$(curl -X POST -s -w '%{http_code}' \
    --cacert $cert \
    -o src/host.json \
    -H "Authorization: Token token=\"$token\"" \
    $baseurl/api/host_factories/hosts?id=$hostid
  )

  if [ $status -eq 201 ]; then
    cat > /etc/conjur.identity <<EOF
    machine $baseurl/api/authn
    login host/$hostid
    password $(jq -r '.api_key' src/host.json)
EOF
    echo '...complete'
  else
    echo "Error! HTTP response: $status"
    exit 1
  fi

  echo "-----"
}

main
