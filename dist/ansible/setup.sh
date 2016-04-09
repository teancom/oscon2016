#!/bin/bash

set -e

id=$(cat /etc/project-id)

cat << EOF > inventory
[apps]
app.${id}.x.pifft.com

[swarms]
swarm-[1:3].${id}.x.pifft.com
EOF

projectVars=/home/workshop/ansible/project.yml

if [[ ! -f $projectVars ]]; then
  cat << EOF > $projectVars
---
project_id: $id
project_domain: x.pifft.com
EOF
fi

ansible-playbook \
  -i inventory site.yml \
  -e @$projectVars \
  $@
