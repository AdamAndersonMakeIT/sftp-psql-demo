#!/bin/sh

# Set up psql-based ssh auth

DBIP=$(getent hosts $DBHOST|awk '{print $1}')
echo Resolved $DBHOST to $DBIP

TABLENAME=sftp_users


# Enable SFTP

sed -i '/Subsystem/d' /etc/ssh/sshd_config
sed -i '/X11Forwarding/d' /etc/ssh/sshd_config
sed -i '/AllowTcpForwarding/d' /etc/ssh/sshd_config
#sed -i '/ForceCommand/d' /etc/ssh/sshd_config
sed -i '/ChrootDirectory/d' /etc/ssh/sshd_config
sed -i '/LogLevel/d' /etc/ssh/sshd_config

echo Subsystem sftp internal-sftp >> /etc/ssh/sshd_config
echo X11Forwarding no >> /etc/ssh/sshd_config
echo AllowTcpForwarding no >> /etc/ssh/sshd_config
#echo ForceCommand internal-sftp >> /etc/ssh/sshd_config
echo ChrootDirectory /home/%u >> /etc/ssh/sshd_config
echo LogLevel VERBOSE >> /etc/ssh/sshd_config

# Start ssh server

/usr/sbin/sshd -De

echo SFTP server is exiting.
