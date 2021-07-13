# NOTE: This script encapsulates the settings imported by benchmark.sh for preparing data and benchmarking.

# no of threads to run load test with
THREADS="1 2 4 8 16 32 64"

# no of tables to generate; we need to manually update this
NTABLES=100

# no of rows with each table
NROWS=5000000

# database configuration
DB_TYPE=pgsql
DB_USER=sbtest
DB_PASS=sbtest
DB_NAME=sbtest

DURATION_SECONDS=600

# reporting data point from sysbench every sec like thds, tps, qps (r/w/o), p95 latency, error etc).
# generated data will be plotted in gnu plot which will help us see the variance in addition to generated summary data from sysbench
REPORTING_SECONDS=1

# lua script is installed as part of sysbench installation. Script generates read intensive OLTP workload
TEST_TYPE=/usr/share/sysbench/oltp_read_write.lua
