docker run -it --rm -w /output -v $PWD:/datasets/ postgres:12 pgbench $@