#!/bin/bash

set -e

id=$(cat /etc/project-id)
domain=$(cat /etc/project-domain)

cat << EOF > inventory
[apps]
app.${id}.${domain}

[swarms]
swarm-[1:3].${id}.${domain}

[shells]
shell.${id}.${domain}
EOF

projectVars=/home/workshop/ansible/project.yml

if [[ ! -f $projectVars ]]; then
  cat << EOF > $projectVars
---
project_id: $id
project_domain: ${domain}
EOF
fi

ansible-playbook \
  -i inventory site.yml \
  -e @$projectVars \
  $@
