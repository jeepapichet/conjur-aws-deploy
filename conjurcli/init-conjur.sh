#!/bin/bash
set -e

conjur init -h conjur.cyberark-demo.com -a mydemo --force=yes
conjur authn -u admin -p Cyberark1
conjur policy load --as-group-security_admin demopolicy.yml
