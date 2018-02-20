#!/bin/bash

function main() {
    echo '-----'
    hostfactory_create
}

function hostfactory_create(){
    #Create new hostfactory token
    local api=$(cat ~/.netrc | grep password | awk '$1=="password"{print $2}')
    printf "This is the API key = $api\n"
    local auth_token=$(curl -s -k -H "Content-Type: text/plain" -X POST -d "$api" https://jenkins/api/authn/users/admin/authenticate)
    local token=$(echo -n $auth_token | base64 | tr -d '\r\n')
    printf "\nThe token is: $token\n"
    local hostfactory_search=$(curl -s -k -X GET -H "Authorization: Token token=\"$token\"" https://jenkins/api/authz/admin/resources/host_factory | jq '.[] | .id ')
    printf "\nThe list of hostfactories:\n$hostfactory_search\n"
    local date=$(date --iso-8601)
    local time_hours=$(date +%H)
    local time_minutes=$(date +%M)
    local time_seconds=$(date -d "+ 20 seconds" +%S)
	  local hostfactory=$(curl -s -k -X POST -H "Authorization: Token token=\"$token\"" "https://jenkins/api/host_factories/jenkins%2Fjenkins_factory/tokens?expiration=${date}T${time_hours}%3A${time_minutes}%3A${time_seconds}-05%3A00")
    local hostfactory_token=$(echo "$hostfactory" | jq '.[] | .token')
    local hostfactory_expiration=$(echo "$hostfactory" | jq '.[] | .expiration')
    printf "The hostfactory token is: $hostfactory_token\n"
    printf "The hostfactory token expires on: $hostfactory_expiration\n"
}

main
