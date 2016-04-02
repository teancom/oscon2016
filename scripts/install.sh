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
      file: path=/home/fedora/.doctlcfg state=touch owner=fedora mode=0600
      when: doctl_dir.stat.exists == False
    - name: add access token to doctl config
      lineinfile: "dest=/home/fedora/.doctlcfg line='access-token: $token' state=present"
      when: doctl_dir.stat.exists == False

    - name: check for terraform
      stat: path=/opt/terraform
      register: terraform_dir
    - name: download terraform
      get_url:
        url=https://releases.hashicorp.com/terraform/0.6.14/terraform_0.6.14_linux_amd64.zip
        dest=$workDir/terraform.zip
      when: doctl_dir.stat.exists == False
    - name: create terraform directory
      file: path=/opt/terraform state=directory mode=0755
      when: doctl_dir.stat.exists == False
    - name: unarchive terraform
      unarchive: src=$workDir/terraform.zip dest=/opt/terraform copy=no
      when: doctl_dir.stat.exists == False
    - name: symlink terraform to /usr/local/bin
      shell: "/usr/bin/ln -sf /opt/terraform/* /usr/local/bin"
      when: doctl_dir.stat.exists == False

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
    - name: allow haproxy to connect to ports
      shell: "/usr/sbin/setsebool -P haproxy_connect_any 1"
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

EOF

sudo ansible-playbook $playbook