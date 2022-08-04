#!/bin/bash
DOMAINS="google.com s3.us-east-1.amazonaws.com slashdot.org pornhub.com cnn.com"

for d in $DOMAINS
do
	curl -L -s -o /dev/null -w "trying: $d returns: %{http_code}\n" https://$d/ --max-time 5
done
