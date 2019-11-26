#!/bin/bash
set -e

if [ $# -eq 0 ]
  then
    echo "Please provide stack name"
    echo "Usage: $0 <stack-name>"
    exit -1
fi

####### Define parameters here #######
DAP_DNS_NAME=dap.yourdomain.com
DAP_MASTER_PASSWORD="P@ssw0rd123!"
S3BucketName="cyberark-cloudformation"
######################################

# Clean up Route53 record if exists
./delete_route53_recordset.sh $DAP_DNS_NAME"."

aws s3 cp conjur-cfn-template.json s3://$S3BucketName/conjur-cfn-template.json
#aws s3 cp conjur-cfn-params.json s3://$S3BucketName/conjur-cfn-params.json
aws cloudformation validate-template --template-url=https://s3-ap-southeast-1.amazonaws.com/$S3BucketName/conjur-cfn-template.json

aws cloudformation create-stack --stack-name $1 --template-url https://s3-ap-southeast-1.amazonaws.com/$S3BucketName/conjur-cfn-template.json --capabilities CAPABILITY_IAM --disable-rollback

echo "Waiting for EC2 instance to start"
sleep 60
echo "Waiting for Conjur Master to be ready"

until $(curl --output /dev/null --silent --head --fail -k https://$DAP_DNS_NAME); do
    printf '.'
    sleep 5
done

echo "Conjur Master is ready"
echo "Load sample policies"

rm -f conjur-*.pem || true
rm -f .conjurrc || true
rm -f .netrc || true

docker run --rm -i -v $(pwd):/root cyberark/conjur-cli:5 init -u https://$DAP_DNS_NAME -a demo --force=yes <<EOL
yes
EOL
docker run --rm -v $(pwd):/root cyberark/conjur-cli:5 authn login -u admin -p $DAP_MASTER_PASSWORD
docker run --rm -v $(pwd):/root cyberark/conjur-cli:5 policy load root /root/policy/demo-policy.yml
docker run --rm -v $(pwd):/root cyberark/conjur-cli:5 policy load root /root/policy/aws-iam-policy.yml
docker run --rm -v $(pwd):/root cyberark/conjur-cli:5 variable values add myawsapp/database/username demouser
docker run --rm -v $(pwd):/root cyberark/conjur-cli:5 variable values add myawsapp/database/password `openssl rand -base64 15`
