FROM ubuntu:24.04

WORKDIR /tmp
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
     openssh-server net-tools \
  && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log* /var/log/apt/*

RUN mkdir -p /var/run/sshd
COPY entrypoint.sh /entrypoint.sh

EXPOSE 22
CMD [ "/entrypoint.sh" ]

HEALTHCHECK CMD netstat -plnt | grep -q sshd || exit 1
