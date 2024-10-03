#!/bin/bash

if psql -U "$POSTGRES_USER" postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DBUSER'" | grep -q 1
then
	echo "User $DBUSER already exists; skipping initialization"
else
	psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" postgres <<-EOSQL

create user $DBUSER with createrole superuser password '$DBPASSWORD';
create database $DBNAME with owner $DBUSER;
EOSQL

  echo Created database user $DBUSER with password: $DBPASSWORD
  echo

  export PGPASSWORD=$DBPASSWORD
  psql -v ON_ERROR_STOP=1 -U "$DBUSER" $DBNAME <<-EOSQL

create extension if not exists pgcrypto;
create sequence sftp_users_uid increment 1 start 1982;
create table sftp_users (
  uid integer not null default nextval('sftp_users_uid'::text),
  login varchar(64) not null primary key,
  password varchar(64) not null,
  fixed boolean not null default false
);

insert into sftp_users (login, password) values ('test', crypt('test',gen_salt('md5')));

EOSQL

  echo Created Table sftp_users and added SFTP user test with password: test
fi
