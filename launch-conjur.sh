#!/bin/bash
set -e
aws s3 cp conjur-cfn.json s3://cyberark-cloudformation/conjur-cfn.json
aws cloudformation validate-template --template-url=https://s3-ap-southeast-1.amazonaws.com/cyberark-cloudformation/conjur-cfn.json

aws cloudformation create-stack --stack-name $1 --template-url https://s3-ap-southeast-1.amazonaws.com/cyberark-cloudformation/conjur-cfn.json --capabilities CAPABILITY_IAM --disable-rollback

echo "Waiting for EC2 instance to start"
sleep 70
echo "Waiting for Conjur Server to be ready"

until $(curl --output /dev/null --silent --head --fail -k https://conjur.cyberark-demo.com); do
    printf '.'
    sleep 5
done

rm conjurcli/*.pem || true
rm conjurcli/.conjurrc || true

docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:5 init -u https://conjur.cyberark-demo.com -a demo --force=yes <<EOL
yes
EOL
docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:5 authn login -u admin -p Cyberark1
docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:5 policy load root demo-policy.yml
