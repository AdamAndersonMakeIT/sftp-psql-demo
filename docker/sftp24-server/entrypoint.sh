#!/bin/sh

# Set up psql-based ssh auth

DBIP=$(getent hosts $DBHOST|awk '{print $1}')
echo Resolved $DBHOST to $DBIP

TABLENAME=sftp_users

cat <<EOF > /etc/nss-pgsql.conf
connectionstring = hostaddr=$DBIP dbname=$DBNAME user=$FTPDBUSER password=$FTPDBPASSWORD connect_timeout=2
getpwnam = SELECT login AS username,'x' as passwd,login as gecos,'/home/' || login AS homedir,'/bin/bash' as shell,uid,uid as gid FROM $TABLENAME WHERE login = \$1
getpwuid = SELECT login AS username,'x' as passwd,login as gecos,'/home/' || login AS homedir,'/bin/bash' as shell,uid,uid as gid FROM $TABLENAME WHERE uid = \$1
getgroupmembersbygid = SELECT login AS username FROM $TABLENAME WHERE uid = \$1
getgrnam = SELECT login AS groupname,'x' as passwd,uid as gid,ARRAY[login] AS members FROM $TABLENAME WHERE login = \$1
getgrgid = SELECT login AS groupname,'x' as passwd,uid as gid,ARRAY[login] AS members FROM $TABLENAME WHERE uid = \$1
groups_dyn = SELECT uid AS gid FROM $TABLENAME WHERE login = \$1 AND uid <> \$2
allusers = SELECT login AS username,'x' as passwd,login as gecos,'/home/' || login AS homedir,'/bin/bash' as shell,uid,uid as gid FROM $TABLENAME
allgroups = SELECT login AS groupname,'x' as passwd,uid as gid,ARRAY[login] AS members FROM $TABLENAME
EOF

cat <<EOF > /etc/nss-pgsql-root.conf
gshadowconnectionstring = hostaddr=$DBIP dbname=$DBNAME user=$FTPDBUSER password=$FTPDBPASSWORD connect_timeout=2
shadowconnectionstring = hostaddr=$DBIP dbname=$DBNAME user=$FTPDBUSER password=$FTPDBPASSWORD connect_timeout=2
connectionstring = hostaddr=$DBIP dbname=$DBNAME user=$FTPDBUSER password=$FTPDBPASSWORD connect_timeout=2
shadowbyname = SELECT login AS shadow_name, password AS shadow_passwd, 14087 AS shadow_lstchg, 0 AS shadow_min, 99999 AS shadow_max, 7 AS shadow_warn, NULL AS shadow_inact, NULL AS shadow_expire, NULL AS shadow_flag FROM $TABLENAME WHERE login = \$1
shadow = SELECT login AS shadow_name, password AS shadow_passwd, 14087 AS shadow_lstchg, 0 AS shadow_min, 99999 AS shadow_max, 7 AS shadow_warn, NULL AS shadow_inact, NULL AS shadow_expire, NULL AS shadow_flag FROM $TABLENAME
gshadow = SELECT login AS shadow_name, 'x' AS shadow_passwd, 14087 AS shadow_lstchg, 0 AS shadow_min, 99999 AS shadow_max, 7 AS shadow_warn, NULL AS shadow_inact, NULL AS shadow_expire, NULL AS shadow_flag FROM $TABLENAME
EOF
chmod 0600 /etc/nss-pgsql-root.conf

cat <<EOF > /etc/pam_pgsql.conf
connect = hostaddr=$DBIP dbname=$DBNAME user=$FTPDBUSER password=$FTPDBPASSWORD connect_timeout=2
auth_query = select password from $TABLENAME where login = %u
acct_query = select false, false, false from $TABLENAME where login = %u

pw_type = crypt
debug = 1
EOF


# Enable SFTP

#sed -i '/Subsystem/d' /etc/ssh/sshd_config
sed -i '/X11Forwarding/d' /etc/ssh/sshd_config
sed -i '/AllowTcpForwarding/d' /etc/ssh/sshd_config
#sed -i '/ForceCommand/d' /etc/ssh/sshd_config
#sed -i '/ChrootDirectory/d' /etc/ssh/sshd_config
sed -i '/LogLevel/d' /etc/ssh/sshd_config

#echo Subsystem sftp internal-sftp >> /etc/ssh/sshd_config
echo X11Forwarding no >> /etc/ssh/sshd_config
echo AllowTcpForwarding no >> /etc/ssh/sshd_config
#echo ForceCommand internal-sftp >> /etc/ssh/sshd_config
#echo ChrootDirectory /home/%u >> /etc/ssh/sshd_config
echo LogLevel VERBOSE >> /etc/ssh/sshd_config

# Start ssh server

/usr/sbin/sshd -ddddDe

echo SFTP server is exiting.
