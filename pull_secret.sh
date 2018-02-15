#! /bin/bash -e
function main() {
  echo "-----"
  fetch_secret
}

function fetch_secret() {
	local X=$(conjur variable value jenkins/git/username)
	echo "Secret=$X" 
}

main
