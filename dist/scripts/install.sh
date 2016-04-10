#!/usr/bin/env bash

token=$(cat /etc/digitalocean-token)
id=$(cat /etc/project-id)
workDir=/tmp/.install
playbook=${workDir}/bootstrap.yml
user=workshop
group=workshop

doctlVer="1.0.1"
tfVer="0.6.14"

# install shell components

set -e

mkdir -p $workDir

cat << EOF > $playbook
- hosts: localhost
  connection: local
  tasks:
    - name: install required packages
      apt: name="{{ item }}" state=present update_cache=yes cache_valid_time=3600
      with_items:
        - unzip
        - haproxy
        - python-netaddr
        - git
        - default-jre

    - name: check for doctl
      stat: path=/opt/doctl
      register: doctl_dir
    - name: download doctl
      get_url:
        url=https://github.com/digitalocean/doctl/releases/download/v${doctlVer}/doctl-${doctlVer}-linux-amd64.tar.gz
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
      file: path=/home/${user}/.doctlcfg state=touch owner=${user} mode=0600
      when: doctl_dir.stat.exists == False
    - name: add access token to doctl config
      lineinfile: "dest=/home/${user}/.doctlcfg line='access-token: $token' state=present"
      when: doctl_dir.stat.exists == False

    - name: check for jenkins cli script
      stat: path=/usr/local/bin/jenkins-cli.sh
      register: jenkins_bin
    - name: download jenkins cli
      get_url:
        url=https://s3.pifft.com/oscon2016/jenkins-cli.sh
        dest=/usr/local/bin/jenkins-cli.sh
        mode=0755
      when: jenkins_bin.stat.exists == False

    - name: check for terraform
      stat: path=/opt/terraform
      register: terraform_dir
    - name: download terraform
      get_url:
        url=https://releases.hashicorp.com/terraform/${tfVer}/terraform_${tfVer}_linux_amd64.zip
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

    - name: check for terraform config
      stat: path=/home/${user}/infra
    - name: download terraform config
      get_url:
        url=https://s3.pifft.com/oscon2016/infra.tar.gz
        dest=$workDir/infra.tar.gz
        force=yes
    - name: unarchive terraform config
      unarchive: src=$workDir/infra.tar.gz dest=/home/${user} owner=${user} group=${group} copy=no

    - name: check for ansible config
      stat: path=/home/${user}/ansible
    - name: download ansible config
      get_url:
        url=https://s3.pifft.com/oscon2016/ansible.tar.gz
        dest=$workDir/ansible.tar.gz
        force=yes
    - name: unarchive ansible config
      unarchive: src=$workDir/ansible.tar.gz dest=/home/${user} owner=${user} group=${group} copy=no

    - name: add default search domain
      lineinfile: dest=/etc/resolvconf/resolv.conf.d/base line="domain ${id}.x.pifft.com" state=present
      notify: update resolvconf

    - file: path=/home/${user}/.shell-configured mode=0600 state=touch owner=${user} group=${group}

    - name: add git lol alias
      command: git config --global alias.lol "log --all --graph --pretty=format:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"

  handlers:
    - name: update resolvconf
      command: resolvconf -u

EOF

sudo ansible-playbook $playbook
sudo rm -rf /home/${user}/.ansible