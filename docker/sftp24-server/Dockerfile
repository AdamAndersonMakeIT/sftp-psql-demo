FROM ubuntu:22.04 AS legacy-libpam

RUN apt-get update \
    && apt-get install --no-install-recommends -y libpam-pgsql \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log* /var/log/apt/*

FROM ubuntu:24.04

WORKDIR /tmp
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install --no-install-recommends -y \
     openssh-server libnss-pgsql2 net-tools \
  && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log* /var/log/apt/*

RUN mkdir -p /var/run/sshd /lib/security
COPY --from=legacy-libpam /lib/security/pam_pgsql.so /lib/security/pam_pgsql.so
COPY etc/pam.d/sshd /etc/pam.d/sshd
COPY etc/nsswitch.conf /etc/nsswitch.conf
COPY entrypoint.sh /entrypoint.sh

EXPOSE 22
CMD [ "/entrypoint.sh" ]

HEALTHCHECK CMD netstat -plnt | grep -q sshd || exit 1
