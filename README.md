# conjur-aws-deploy

Cloud Formation template and bash script to deploy Conjur Master. 
You need to get access to Conjur AMI for your AWS account first. The host running the script must have Docker engine and conjur-cli image loaded.

`launch-conjur.sh` script will do the followings;  
- Provision a conjur EC2 instance from AMI
- Configure its role as Master
- Load sample policies 
- Update Route53 record


Before running the script, update parameters in `launch-conjur.sh` and `conjur-cfn-template` to match your environment.
