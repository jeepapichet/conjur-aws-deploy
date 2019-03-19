#!/bin/bash


#For Conjur version 4 API

conjurCert="./conjur-mydemo.pem"
CONJUR_APPLIANCE_URL="https://conjur.cyberark-demo.com/api"
CONJUR_CIRCLECI_MASTER_LOGIN="host/circleci/master"
CONJUR_CIRCLECI_MASTER_API_KEY="3vw8ed9dcpbk147epdf2hxrvbn245d1f0cdecy41cnphyc3xcn63b"
hf_id="circleci/executor_factory"

CIRCLECI_JOB="my_circleci_job_name"

CONJUR_AUTHN_USERNAME="host/circleci/$CIRCLECI_JOB"


urlencoded_login=$(echo $CONJUR_CIRCLECI_MASTER_LOGIN | sed 's=/=%2F=g')
echo "encoded login = $urlencoded_login"
echo "apikey = $CONJUR_CIRCLECI_MASTER_API_KEY"

auth=$(curl -s --cacert $conjurCert -H "Content-Type: text/plain" -X POST -d "$CONJUR_CIRCLECI_MASTER_API_KEY" $CONJUR_APPLIANCE_URL/authn/users/$urlencoded_login/authenticate)

echo "auth = $auth"

auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
echo "auth_token = $auth_token"

urlencoded_hf_id=$(echo $hf_id | sed 's=/=%2F=g')

token_exp_time=$(date --iso-8601=seconds --date="120 seconds")
urlencoded_token_exp_time=$(echo $token_exp_time | sed 's=/=%2F=g; s= =%20=g; s=:=%3A=g; s=+=%2B=g')

echo "encoded_hf_id = $urlencoded_hf_id"
echo "token exp = $token_exp_time = $urlencoded_token_exp_time"

response=$(curl -s \
              --cacert $conjurCert \
              -X POST -H "Authorization: Token token=\"$auth_token\"" \
              $CONJUR_APPLIANCE_URL/host_factories/$urlencoded_hf_id/tokens?expiration=$urlencoded_token_exp_time)

hf_token=$(echo $response | jq -r '.[].token') 
echo "hostfactory token= $hf_token"


urlencoded_hostid=$(echo $CONJUR_AUTHN_USERNAME | sed 's=/=%2F=g')


response=$(curl -s \
         --cacert $conjurCert \
         -X POST -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$hf_token\"" \
         $CONJUR_APPLIANCE_URL/host_factories/hosts?id=$urlencoded_hostid)

CONJUR_AUTHN_API_KEY=$(echo $response | jq -r '.api_key')

echo "HOST ID = $CONJUR_AUTHN_USERNAME"
echo "API KEY = $CONJUR_AUTHN_API_KEY"
