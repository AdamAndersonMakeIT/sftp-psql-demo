#!/usr/bin/env bash

running="$HEALTHCHECK_RUN_FILE"
touch "$running"

TABLENAME=sftp_users
export PGPASSWORD=$DBPASSWORD

pg() {
#    echo "psql -h $DBHOST -U $DBUSER $DBNAME -tAc" "$@" >&2
    psql -h $DBHOST -U $DBUSER $DBNAME -tAc "$@"
}

retries=5
until pg "SELECT 1" 2>/dev/null | grep -q 1
do
    echo postgres is not ready
    sleep 10
    if [ "$?" != "0" ]
    then
        echo >&2
        echo quitting >&2
        exit 137
    fi
    if [ "$((retries--))" -le 0 ]
    then
        echo >&2
        echo postgres is not here >&2
        echo giving up >&2
        exit 1
    fi
done
echo postgres is ready

fix() {

    # Find users that aren't fixed and fix them.

    pg "SELECT uid, login from $TABLENAME where not fixed" | \
    while IFS="|" read uid login
    do
        echo -n "Fixing filesystem for $login ($uid) ... "

        # Fix permissions/ownership of user homedir for SFTP access.
        mkdir -p /home/$login/uploads
        chown 0:0 /home /home/$login
        chmod 755 /home /home/$login
        chown -R $uid:$uid /home/$login/uploads
        chmod 700 /home/$login/uploads

        psql -tA -h $DBHOST -U $DBUSER $DBNAME \
          -c "UPDATE $TABLENAME SET fixed = true WHERE uid = $uid"
    done
}

touch "$running"
fix

while sleep 60
do
    touch "$running"
    fix
done

echo filesystem fixer is exiting.
