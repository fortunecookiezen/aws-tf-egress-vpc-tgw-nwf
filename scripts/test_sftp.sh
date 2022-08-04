#!/bin/bash
set -euf -o pipefail
$(sftp -o "BatchMode=yes" -o "ConnectTimeout=5" thankyou@itcsubmit.wustl.edu) 
