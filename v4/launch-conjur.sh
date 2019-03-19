#!/bin/bash
set -e
aws s3 cp conjur-cft.json s3://cyberark-cloudformation/conjur-cft.json
aws cloudformation validate-template --template-url=https://s3-ap-southeast-1.amazonaws.com/cyberark-cloudformation/conjur-cft.json

aws cloudformation create-stack --stack-name $1 --template-url https://s3-ap-southeast-1.amazonaws.com/cyberark-cloudformation/conjur-cft.json --capabilities CAPABILITY_IAM --disable-rollback

echo "Waiting for Conjur Server to be ready"

until $(curl --output /dev/null --silent --head --fail -k https://conjur.cyberark-demo.com); do
    printf '.'
    sleep 5
done

rm conjurcli/*.pem || true
rm conjurcli/.conjurrc || true

docker run --rm -i -v $(pwd)/conjurcli:/root cyberark/conjur-cli:4 init -h conjur.cyberark-demo.com --force=yes <<EOL
yes
EOL
docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:4 authn login -u admin -p Cyberark1
docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:4 plugin install policy
docker run --rm -v $(pwd)/conjurcli:/root cyberark/conjur-cli:4 policy load --as-group=security_admin demo-policy.yml
