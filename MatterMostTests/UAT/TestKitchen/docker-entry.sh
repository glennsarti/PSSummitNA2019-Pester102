#!/bin/bash
echo "Starting MySQL"
/entrypoint.sh mysqld &

until mysqladmin -hlocalhost -P3306 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" processlist &> /dev/null; do
        echo "MySQL still not ready, sleeping"
        sleep 5
done

echo "Updating CA certificates"
update-ca-certificates --fresh >/dev/null

echo "Starting SSH"
service ssh start

# Turn on bash's job control
set -m

echo "Starting PoshBot (background)..."
pwsh -NonInteractive -File ./RunPoshBot.ps1 > /tmp/RunPoshBot.log &

echo "Starting platform"
cd mattermost
exec ./bin/mattermost --config=config/config_docker.json
