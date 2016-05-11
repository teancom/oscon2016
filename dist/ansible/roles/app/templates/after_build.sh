#!/usr/bin/env bash

# notify after build

set -e

webHookURL="https://devconfbot.ngrok.io/webhook"
id=$(cat /etc/project-id)

json=$(cat <<eof
{
  "type": "jenkins",
  "project_id": "$id",
  "options": {
    "number": "$BUILD_ID",
    "name": "$JOB_NAME"
  }
}
eof
)

curl -X "POST" $webHookURL \
  -H "Content-Type: application/json" \
  -d "$json"