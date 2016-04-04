#!/usr/bin/env bash

token=$(cat /etc/digitalocean-token)

# install shell components

. /etc/os-release

case "$ID" in
ubuntu)
  sudo apt-get install -y -qq software-properties-common
  sudo apt-add-repository ppa:ansible/ansible
  sudo apt-get update -qq
  sudo apt-get install -y -qq ansible unzip haproxy python-netaddr
  ;;
*) echo "unknown os"
  exit 1
  ;;
esac

set -e

workDir=/tmp/.install
playbook=${workDir}/bootstrap.yml

mkdir -p $workDir

cat << EOF > $playbook
- hosts: localhost
  connection: local
  tasks:
    - name: check for doctl
      stat: path=/opt/doctl
      register: doctl_dir
    - name: download doctl
      get_url:
        url=https://github.com/digitalocean/doctl/releases/download/v1.0.0/doctl-1.0.0-linux-amd64.tar.gz
        dest=$workDir/doctl.tar.gz
      when: doctl_dir.stat.exists == False
    - name: create doctl directory
      file: path=/opt/doctl state=directory mode=0755
      when: doctl_dir.stat.exists == False
    - name: unarchive doctl
      unarchive: src=$workDir/doctl.tar.gz dest=/opt/doctl copy=no
      when: doctl_dir.stat.exists == False
    - name: symlink doctl to /usr/local/bin
      file: src=/opt/doctl/doctl dest=/usr/local/bin/doctl state=link
      when: doctl_dir.stat.exists == False
    - name: create doctl config file
      file: path=/home/workshop/.doctlcfg state=touch owner=workshop mode=0600
      when: doctl_dir.stat.exists == False
    - name: add access token to doctl config
      lineinfile: "dest=/home/workshop/.doctlcfg line='access-token: $token' state=present"
      when: doctl_dir.stat.exists == False

    - name: check for terraform
      stat: path=/opt/terraform
      register: terraform_dir
    - name: download terraform
      get_url:
        url=https://releases.hashicorp.com/terraform/0.6.14/terraform_0.6.14_linux_amd64.zip
        dest=$workDir/terraform.zip
      when: terraform_dir.stat.exists == False
    - name: create terraform directory
      file: path=/opt/terraform state=directory mode=0755
      when: terraform_dir.stat.exists == False
    - name: unarchive terraform
      unarchive: src=$workDir/terraform.zip dest=/opt/terraform copy=no
      when: terraform_dir.stat.exists == False
    - name: symlink terraform to /usr/local/bin
      shell: "/bin/ln -sf /opt/terraform/* /usr/local/bin"
      when: terraform_dir.stat.exists == False

    - name: check for kubectl
      stat: path=/usr/local/bin/kubectl
      register: kubectl_bin
    - name: download kubectl
      get_url:
        url=https://s3.pifft.com/oscon2016/kubectl
        dest=/usr/local/bin/kubectl
        mode=0755
      when: kubectl_bin.stat.exists == False

    - name: download haproxy config
      get_url:
        url=https://s3.pifft.com/oscon2016/haproxy.cfg
        dest=/etc/haproxy/haproxy.cfg
        mode=0644
        force=yes
    - name: enable haproxy service
      lineinfile: dest=/etc/default/haproxy regexp=^ENABLED= line=ENABLED=1
    - name: allow haproxy to connect to ports
      shell: "/usr/sbin/setsebool -P haproxy_connect_any 1"
      when: ansible_distribution == "Fedora"
    - name: start haproxy
      service: name=haproxy enabled=yes state=started

    - name: check for k8s bins
      stat: path=/opt/kube-bins
      register: k8s_bins
    - name: download kubernetes distribution
      get_url:
        url=https://s3.pifft.com/oscon2016/k8s-bins.tar.gz
        dest=$workDir/k8s-bins.tar.gz
      when: k8s_bins.stat.exists == False
    - name: create kube bins directory
      file: path=/opt/kube-bins state=directory mode=0755
      when: k8s_bins.stat.exists == False
    - name: unarchive kubernetes bins
      unarchive: src=$workDir/k8s-bins.tar.gz dest=/opt/kube-bins copy=no
      when: k8s_bins.stat.exists == False

    - name: check for terraform config
      stat: path=/home/workshop/infra
      register: infra_dir
    - name: download terraform config
      get_url:
        url=https://s3.pifft.com/oscon2016/infra.tar.gz
        dest=$workDir/infra.tar.gz
      when: infra_dir.stat.exists == False
    - name: unarchive terraform config
      unarchive: src=$workDir/infra.tar.gz dest=/home/workshop owner=workshop group=workshop copy=no
      when: infra_dir.stat.exists == False

    - name: check for k8s ansible config
      stat: path=/home/workshop/ansible
      register: ansible_dir
    - name: download ansible config
      get_url:
        url=https://s3.pifft.com/oscon2016/ansible.tar.gz
        dest=$workDir/ansible.tar.gz
      when: ansible_dir.stat.exists == False
    - name: unarchive ansible config
      unarchive: src=$workDir/ansible.tar.gz dest=/home/workshop owner=workshop group=workshop copy=no
      when: ansible_dir.stat.exists == False

    - name: check for kubectl proxy config
      stat: path=/etc/conf/kubectl-proxy.conf
      register: kubectl_proxy
    - name: download kubectl proxy config
      get_url:
        url=https://s3.pifft.com/oscon2016/kubectl-proxy.conf
        dest=/etc/init/kubectl-proxy.conf
        mode=0644
      when: kubectl_proxy.stat.exists == False
    - name: enable kbuectl-proxy
      service: name=kubectl-proxy enabled=yes

EOF

sudo ansible-playbook $playbook
sudo rm -rf /home/workshop/.ansible