FROM jenkins:1.642.4

USER root
RUN apt-get update \
      && groupadd -g 1001 docker \
      && apt-get install -y apt-transport-https ca-certificates \
      && apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
      && echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list \
      && apt-get update \
      && apt-get install -y sudo docker-engine \
      && rm -rf /var/lib/apt/lists/* \
      && usermod -a -G docker jenkins
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN wget -q https://storage.googleapis.com/golang/go1.6.2.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.6.2.linux-amd64.tar.gz \
      && rm go1.6.2.linux-amd64.tar.gz

USER jenkins
ENV PATH /usr/local/go/bin:$PATH
COPY plugins.txt /usr/share/jenkins/plugins.txt
COPY go.sh /etc/profile.d
COPY gitconfig /var/jenkins_home/.gitconfig
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/plugins.txt