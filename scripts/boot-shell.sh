#!/usr/bin/env bash

token=$1
pubKeyPath=$2
domain="x.pifft.com"
image="ubuntu-14-04-x64"
masterKey=104064

if [[ -z $token || -z $pubKeyPath ]]; then
  echo "usage: $0 <token> <pubkey path>"
  exit 1
fi

if [[ ! -f $pubKeyPath ]]; then
  echo "could not find pub key"
  exit 1
fi

pubKey=$(cat $pubKeyPath)
id=$(echo $RANDOM | md5 | cut -c-1-8)

userData=$(cat <<EOF
#cloud-config

users:
  - name: workshop
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - $pubKey
write_files:
  - encoding: b64
    content: $(echo $id | base64)
    owner: root:root
    path: /etc/project-id
    permissions: '0644'
  - encoding: b64
    content: $(echo $token | base64)
    owner: root:root
    path: /etc/digitalocean-token
    permissions: '0644'
  - encoding: b64
    content: $(echo -e "#!/usr/bin/env bash\ncurl -s https://s3.pifft.com/oscon2016/install.sh | bash" | base64)
    owner: root:root
    path: /usr/local/bin/install-shell.sh
    permissions: '0755'
package_update: true
apt_sources:
  - source: "ppa:gluster/glusterfs-3.5"
  - source: "ppa:ansible/ansible"
packages:
  - glusterfs-client
  - glusterfs-server
  - ansible


EOF
)

dropletName="shell.$id"

echo "creating droplet ${dropletName}"
doctl compute droplet create $dropletName \
  --user-data "$userData" \
  --region nyc1 \
  --size 4gb \
  --ssh-keys $masterKey \
  --image $image \
  --wait

dropletIP=$(doctl compute droplet list $dropletName --no-header --format PublicIPv4)

echo "assigning ip in DNS"
doctl compute domain records create $domain \
  --record-name $dropletName \
  --record-type A \
  --record-data $dropletIP

echo "created ${dropletName}.${domain}"
echo "id: ${id}"
echo "doctl compute ssh workshop@${dropletName}"
