#!/bin/bash

# Default values for environment variables
POSTGRES_ADMIN_USER=${POSTGRES_ADMIN_USER:-"admin"}
POSTGRES_ADMIN_PASSWORD=${POSTGRES_ADMIN_PASSWORD:-"securepassword123"}
POSTGRES_DB=${POSTGRES_DB:-"app_db"}

# Create log directory with proper permissions
mkdir -p $PGDATA/log
chmod 700 $PGDATA/log

# Initialize the PostgreSQL database cluster
/usr/local/pgsql/bin/initdb -D $PGDATA

# Allow all remote connections using md5 authentication
echo "host all all 0.0.0.0/0 md5" >> $PGDATA/pg_hba.conf

# Allow PostgreSQL to listen on all interfaces
echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf

# Start PostgreSQL temporarily for initialization
/usr/local/pgsql/bin/pg_ctl -D $PGDATA -l "$PGDATA/log/init.log" start

# Wait for PostgreSQL to be ready
until pg_isready -h localhost -p 5432; do
  echo "Waiting for PostgreSQL to start..."
  sleep 1
done

# Create admin user with password from environment variables
psql -d postgres -c "CREATE USER $POSTGRES_ADMIN_USER WITH SUPERUSER PASSWORD '$POSTGRES_ADMIN_PASSWORD';"

# Create database and extensions if they don't exist
psql -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'" | grep -q 1 || createdb $POSTGRES_DB
psql -d $POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS vector;"
psql -d $POSTGRES_DB -c "CREATE EXTENSION IF NOT EXISTS age;"
psql -d $POSTGRES_DB -c "LOAD 'age';"
psql -d $POSTGRES_DB -c "SET search_path = ag_catalog, '$user', public;"

# Stop PostgreSQL - the container's CMD will start it properly
/usr/local/pgsql/bin/pg_ctl -D $PGDATA stop

