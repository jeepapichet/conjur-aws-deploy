#!/bin/sh

# NOTE: Delete recordset if exist
# DNS Name must have . at the end

if [ $# -eq 0 ]
  then
    echo "Please provide DNS name to delete. Name must have '.' at the end e.g. dap.yourdomain.com."
    echo "Usage: $0 <DNS-NAME>"
    exit -1
fi

DNS_NAME=$1

RECORD_NAME=${DNS_NAME%%.*}
DOMAIN_NAME=${DNS_NAME#*.}
HOSTED_ZONE_ID=`aws route53 list-hosted-zones-by-name --dns-name $DOMAIN_NAME  | jq -r .HostedZones[].Id`

#echo "DNS_NAME=$DNS_NAME"
#echo "DOMAIN=$DOMAIN_NAME"
#echo "RECORD=$RECORD_NAME"
#echo "HZ="$HOSTED_ZONE_ID

#aws route53 list-resource-record-sets --hosted-zone-id=$HOSTED_ZONE_ID | jq '.ResourceRecordSets[]'
targetrecord=`aws route53 list-resource-record-sets --hosted-zone-id=$HOSTED_ZONE_ID | jq ".ResourceRecordSets[] | select (.Name == \"$DNS_NAME\")"`

RESOURCE_VALUE=`echo $targetrecord | jq -r '.ResourceRecords[].Value'`
RECORD_TYPE=`echo $targetrecord | jq -r '.Type'`
TTL=`echo $targetrecord | jq -r '.TTL'`

#echo RV=$RESOURCE_VALUE
#echo RT=$RECORD_TYPE
#echo TTL=$TTL

if [ -z $RESOURCE_VALUE ] 
  then
    echo "Record $DNS_NAME not found - Do nothing"
    exit 0
fi


#Start delete record

JSON_FILE="tmp_json_file"

(
cat <<EOF
{
    "Comment": "Delete single record set",
    "Changes": [
        {
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "$DNS_NAME",
                "Type": "$RECORD_TYPE",
                "TTL": $TTL,
                "ResourceRecords": [
                    {
                        "Value": "${RESOURCE_VALUE}"
                    }
                ]                
            }
        }
    ]
}
EOF
) > $JSON_FILE

echo "Deleting DNS Record set $DNS_NAME"
aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://$JSON_FILE

echo "Deleting record set ..."
echo
rm -f $JSON_FILE
echo "Operation Completed."
