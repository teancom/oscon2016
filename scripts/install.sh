#!/bin/sh

token=$(cat /etc/digitalocean-token)

# install shell components

# ansible
sudo dnf install -y -q ansible libselinux-python unzip haproxy python-netaddr

workDir=/tmp/.install
playbook=${workDir}/bootstrap.yml

mkdir -p $workDir

cat << EOF > $playbook
- hosts: localhost
  connection: local
  tasks:
    - name: download doctl
      get_url:
        url=https://github.com/digitalocean/doctl/releases/download/v1.0.0/doctl-1.0.0-linux-amd64.tar.gz
        dest=$workDir/doctl.tar.gz
    - name: create doctl directory
      file: path=/opt/doctl state=directory mode=0755
    - name: unarchive doctl
      unarchive: src=$workDir/doctl.tar.gz dest=/opt/doctl copy=no
    - name: symlink doctl to /usr/local/bin
      file: src=/opt/doctl/doctl dest=/usr/local/bin/doctl state=link
    - name: create doctl config file
      file: path=/home/fedora/.doctlcfg state=touch owner=fedora mode=0600
    - name: add access token to doctl config
      lineinfile: "dest=/home/fedora/.doctlcfg line='access-token: $token' state=present"

    - name: download terraform
      get_url:
        url=https://releases.hashicorp.com/terraform/0.6.14/terraform_0.6.14_linux_amd64.zip
        dest=$workDir/terraform.zip
    - name: create terraform directory
      file: path=/opt/terraform state=directory mode=0755
    - name: unarchive terraform
      unarchive: src=$workDir/terraform.zip dest=/opt/terraform copy=no
    - name: symlink terraform to /usr/local/bin
      shell: "/usr/bin/ln -sf /opt/terraform/* /usr/local/bin"

    - name: download kubectl
      get_url:
        url=https://s3.pifft.com/oscon2016/kubectl
        dest=/usr/local/bin/kubectl
        mode=0755

    - name: download haproxy
      get_url:
        url=https://s3.pifft.com/oscon2016/haproxy.cfg
        dest=/etc/haproxy/haproxy.cfg
        mode=0644
    - service: name=haproxy enabled=yes state=started

    - name: download kubernetes distribution
      get_url:
        url=https://s3.pifft.com/oscon2016/k8s-bins.tar.gz
        dest=$workDir/k8s-bins.tar.gz
    - name: create kube bins directory
      file: path=/opt/kube-bins state=directory mode=0755
    - name: unarchive kubernetes bins
      unarchive: src=$workDir/k8s-bins.tar.gz dest=/opt/kube-bins copy=no

EOF

sudo ansible-playbook $playbook