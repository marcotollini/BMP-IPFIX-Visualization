docker exec timescale_test bash -c 'chmod 755 /docker-entrypoint-initdb.d/3.setup_fn.sh && /docker-entrypoint-initdb.d/3.setup_fn.sh > /dev/null 2>&1'
docker exec timescale_test bash -c 'psql --user "$POSTGRES_USER" -d "$POSTGRES_DB" -Xf /test/*.sql'
