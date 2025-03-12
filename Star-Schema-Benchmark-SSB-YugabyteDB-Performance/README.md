# Running SSB (Star Schema Benchmark) on YugabyteDB

Reference: https://cs.umb.edu/~poneil/StarSchemaB.pdf

- Standard SSB schema (normalized to SSB standards).
- No extra denormalization or restructuring done yet specifically for performance. 


## Overall Notes:

- Current indexing is a first draft by me: a deeper look into it planned for later.
- Results highlight YugabyteDB’s effectiveness at distributed JOINs and aggregations and great performance with PostgreSQL API
- Ideal for mixed OLTP/OLAP/HTAP scenarios, enabling single-database solutions.
- Seeing great performance results against PostgresSQL, considering PostgreSQL has one node usually with non zero RPO fault tolerance 

## My TODO

- update Seed 3 and  with new GUC Setting
- Run Seed 3 and 10 against PG for PG timings 
- check execution plans are optimal from indexing or if i should be looking at a different join order or plan
- Test against preview Yugabyte (2.25)

Summary of Star Schema Benchmark (SSB) Performance on YugabyteDB And PostgreSQL
- Query Parameters used are displayed below 

| Query | Seed(LRows) | PG (6M) | YB (6M) |  | PG (11M) | YB (11M) |
|-------|-------------|---------|---------|--|----------|----------|
| Q1.1  | Time        | 47 ms   | 90 ms   |  | 104 ms   | 167 ms   |
| Q1.2  | Time        | 2 ms    | 8 ms    |  | 6 ms     | 12 ms    |
| Q1.3  | Time        | 1 ms    | 5 ms    |  | 1 ms     | 6 ms     |
| Q2.1  | Time        | 94 ms   | 256 ms  |  | 173 ms   | 660 ms   |
| Q2.2  | Time        | 29 ms   | 65 ms   |  | 53 ms    | 130 ms   |
| Q2.3  | Time        | 5 ms    | 15 ms   |  | 47 ms    | 24 ms    |
| Q3.1  | Time        | 483 ms  | 1 s     |  | 665 ms   | 2 s      |
| Q3.2  | Time        | 83 ms   | 167 ms  |  | 190 ms   | 354 ms   |
| Q3.3  | Time        | 1222 ms | 1 s     |  | 2.5 s    | 2.1 s    |
| Q3.4  | Time        | 11 ms   | 45 ms   |  | 24 ms    | 69 ms    |
| Q4.1  | Time        | 483 ms  | 795 ms  |  | 1.3 s    | 1.8 s    |
| Q4.2  | Time        | 537 ms  | 914 ms  |  | 1.3 s    | 2.1 s    |
| Q4.3  | Time        | 183 ms  | 266 ms  |  | 493 ms   | 485 ms   |

## My TODO

- Review Q3.1 for optimisation 
- Run 17M and 60M on PG


| Query | Seed(LRows) | YB (17M) | YB (60M) |
|-------|-------------|----------|-----------|
| Q1.1  | Time        | 242 ms   | 624 ms    |
| Q1.2  | Time        | 16 ms    | 28 ms     |
| Q1.3  | Time        | 1 ms     | 5 ms      |
| Q2.1  | Time        | 1.2 s    | 2.0 s     |
| Q2.2  | Time        | 214 ms   | 428 ms    |
| Q2.3  | Time        | 47 ms    | 24 ms     |
| Q3.1  | Time        | 3.0 s    | 9.7 s     |
| Q3.2  | Time        | 507 ms   | 1.7 s     |
| Q3.3  | Time        | 731 ms   | 2.4 s     |
| Q3.4  | Time        | 87 ms    | 245 ms    |
| Q4.1  | Time        | 2.8 s    | 10.8 s    |
| Q4.2  | Time        | 2.9 s    | 11.8 s    |
| Q4.3  | Time        | 731 ms   | 2.4 s     |

---

## Summary of Test Environment:

- YugabyteDB 2024.2
- Deployed on a 3-node cluster in public cloud
- Fault tolerance: Survives complete loss of one availability zone
- Replication factor: 3

---

## Repository Contents:

- Database schema and index definitions
- Data generation scripts (`dbgen`)
- Load procedures
- Benchmark queries with detailed execution plans

---

### Contributing:

Improvements and optimizations are welcome! (indexing, hinting, GUC setting)  Or testing against Aurora, RDS etc.

---
My intallation route on redhat.
---

```
sudo yum install git make gcc dos2unix -y 
git clone https://github.com/vadimtk/ssb-dbgen.git
cd ssb-dbgen
make
wget https://downloads.yugabyte.com/releases/2.25.0.0/yugabyte-client-2.25.0.0-b489-linux-x86_64.tar.gz
tar xvfz yugabyte-client-2.25.0.0-b489-linux-x86_64.tar.gz
cd yugabyte-client-2.25.0.0
./bin/post_install.sh
echo 'export PATH=$PATH:/home/ec2-user/SSB/ssb-dbgen/yugabyte-client-2.25.0.0/bin' >> ~/.bashrc
source ~/.bashrc
cd /home/ec2-user/SSB/ssb-dbgen
```

-----
How I executed each seed, prepared the files for PostgreSQL and then executed each run.
-----

```
---
COPY 30000
COPY 200000
COPY 2000
COPY 2556
COPY 6001215
---
rm -f *.tbl
./dbgen -s 1 -T c
./dbgen -s 1 -T p
./dbgen -s 1 -T s
./dbgen -s 1 -T d
./dbgen -s 1 -T l
sed -i 's/,$//' *.tbl
export PGPASSWORD="pw!"
ysqlsh -h 10.0.0.61 -c "\i schema_and_data.sql"
ysqlsh -h 10.0.0.61 -c "\i querieswithexplain.sql" > querieswithexplain2024.2_results_SEED_1_new.txt
```

```
---
COPY 60000
COPY 400000
COPY 4000
COPY 2556
COPY 11997996
---
rm -f *.tbl
./dbgen -s 2 -T c
./dbgen -s 2 -T p
./dbgen -s 2 -T s
./dbgen -s 2 -T d
./dbgen -s 2 -T l
sed -i 's/,$//' *.tbl
export PGPASSWORD="pw!"
ysqlsh -h 10.0.0.61 -c "\i schema_and_data.sql"
ysqlsh -h 10.0.0.61 -c "\i querieswithexplain.sql" > querieswithexplain2024.2_results_SEED_2_new.txt
```

```
---
COPY 90000
COPY 400000
COPY 6000
COPY 2556
COPY 17996609
---
rm -f *.tbl
./dbgen -s 3 -T c
./dbgen -s 3 -T p
./dbgen -s 3 -T s
./dbgen -s 3 -T d
./dbgen -s 3 -T l
sed -i 's/,$//' *.tbl
export PGPASSWORD="pw!"
ysqlsh -h 10.0.0.61 -c "\i schema_and_data.sql"
ysqlsh -h 10.0.0.61 -c "\i querieswithexplain.sql" > querieswithexplain2024.2_results_SEED_3_new.txt
```

```
---
COPY 300000
COPY 800000
COPY 20000
COPY 2556
COPY 59986052
---
rm -f *.tbl
./dbgen -s 10 -T c
./dbgen -s 10 -T p
./dbgen -s 10 -T s
./dbgen -s 10 -T d
./dbgen -s 10 -T l
sed -i 's/,$//' *.tbl
export PGPASSWORD="pw!"
ysqlsh -h 10.0.0.61 -c "\i schema_and_data.sql"
ysqlsh -h 10.0.0.61 -c "\i querieswithexplain.sql" > querieswithexplain2024.2_results_SEED_10_new.txt
```


--- 
PG
---


sudo yum install postgresql15-server -y
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo sed -i -e "s/^#*port = .*/port = 5555/" -e "s/^#*listen_addresses = .*/listen_addresses = '*'/" /var/lib/pgsql/15/data/postgresql.conf
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15
sudo systemctl status postgresql-15
sudo -iu postgres psql -p 5555

rm -f *.tbl
./dbgen -s 1 -T c
./dbgen -s 1 -T p
./dbgen -s 1 -T s
./dbgen -s 1 -T d
./dbgen -s 1 -T l
sed -i 's/,$//' *.tbl
cp *.tbl /tmp

cp schema_and_data.sql /tmp/schema_and_data_PG.sql
chmod 644 /tmp/schema_and_data_PG.sql
sudo -iu postgres psql -p 5555 -f /tmp/schema_and_data_PG.sql

cp querieswithexplain.sql /tmp/querieswithexplain.sql
chmod 644 /tmp/querieswithexplain.sql
sudo -iu postgres psql -p 5555 -f /tmp/querieswithexplain.sql > POSTGRES15_querieswithexplain2024.2_results_SEED_1_new.txt

---


rm -f *.tbl
./dbgen -s 2 -T c
./dbgen -s 2 -T p
./dbgen -s 2 -T s
./dbgen -s 2 -T d
./dbgen -s 2 -T l
sed -i 's/,$//' *.tbl
cp *.tbl /tmp

sudo -iu postgres psql -p 5555 -f /tmp/schema_and_data_PG.sqll
sudo -iu postgres psql -p 5555 -f /tmp/querieswithexplain.sql > POSTGRES15_querieswithexplain2024.2_results_SEED_2_new.txt 

---


---
Listing the queries Executed
---

```
select 'Q1.1' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT SUM(lo_extendedprice * lo_discount) AS revenue
FROM lineorder l,
     date_tbl d
WHERE l.lo_orderdate = d.d_datekey
  AND d.d_year = 1993
  AND l.lo_discount BETWEEN 1 AND 3
  AND l.lo_quantity < 25;


select 'Q1.2' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT SUM(lo_extendedprice * lo_discount) AS revenue
FROM lineorder l,
     date_tbl d
WHERE l.lo_orderdate = d.d_datekey
  AND d.d_yearmonthnum = 199401
  AND l.lo_discount BETWEEN 4 AND 6
  AND l.lo_quantity BETWEEN 26 AND 35;

select 'Q1.3' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT SUM(lo_extendedprice * lo_discount) AS revenue
FROM lineorder l,
     date_tbl d
WHERE l.lo_orderdate = d.d_datekey
  AND d.d_weeknuminyear = 6
  AND d.d_year = 1994
  AND l.lo_discount BETWEEN 5 AND 7
  AND l.lo_quantity BETWEEN 26 AND 35;

select 'Q2.1' as query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       p.p_brand1,
       SUM(l.lo_revenue) AS revenue
FROM lineorder l,
     date_tbl d,
     part p,
     supplier s
WHERE l.lo_orderdate = d.d_datekey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_suppkey = s.s_suppkey
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'AMERICA'
GROUP BY d.d_year,
         p.p_brand1
ORDER BY d.d_year,
         p.p_brand1;

select 'Q2.2' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       p.p_brand1,
       SUM(l.lo_revenue) AS revenue
FROM lineorder l,
     date_tbl d,
     part p,
     supplier s
WHERE l.lo_orderdate = d.d_datekey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_suppkey = s.s_suppkey
  AND p.p_brand1 BETWEEN 'MFGR#2221' AND 'MFGR#2228'
  AND s.s_region = 'ASIA'
GROUP BY d.d_year,
         p.p_brand1
ORDER BY d.d_year,
         p.p_brand1;

select 'Q2.3' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       p.p_brand1,
       SUM(l.lo_revenue) AS revenue
FROM lineorder l,
     date_tbl d,
     part p,
     supplier s
WHERE l.lo_orderdate = d.d_datekey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_suppkey = s.s_suppkey
  AND p.p_brand1 = 'MFGR#2239'
  AND s.s_region = 'EUROPE'
GROUP BY d.d_year,
         p.p_brand1
ORDER BY d.d_year,
         p.p_brand1;

select 'Q3.1' as query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT c.c_nation,
       s.s_nation,
       d.d_year,
       SUM(l.lo_revenue) AS revenue
FROM customer c,
     supplier s,
     lineorder l,
     date_tbl d
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_region = 'ASIA'
  AND s.s_region = 'ASIA'
  AND d.d_year BETWEEN 1992 AND 1997
GROUP BY c.c_nation,
         s.s_nation,
         d.d_year
ORDER BY d.d_year,
         revenue DESC;

select 'Q3.2' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT c.c_city,
       s.s_city,
       d.d_year,
       SUM(l.lo_revenue) AS revenue
FROM customer c,
     supplier s,
     lineorder l,
     date_tbl d
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_nation = 'UNITED STATES'
  AND s.s_nation = 'UNITED STATES'
  AND d.d_year BETWEEN 1992 AND 1997
GROUP BY c.c_city,
         s.s_city,
         d.d_year
ORDER BY d.d_year,
         revenue DESC;

select 'Q3.3' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT c.c_city,
       s.s_city,
       d.d_year,
       SUM(l.lo_revenue) AS revenue
FROM customer c,
     supplier s,
     lineorder l,
     date_tbl d
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_orderdate = d.d_datekey
  AND SUBSTRING(c.c_phone, 1, 1) = '3'
  AND SUBSTRING(s.s_phone, 1, 1) = '3'
  AND d.d_year BETWEEN 1992 AND 1997
GROUP BY c.c_city,
         s.s_city,
         d.d_year
ORDER BY d.d_year,
         revenue DESC;

select 'Q3.4' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT c.c_city,
       s.s_city,
       d.d_year,
       SUM(l.lo_revenue) AS revenue
FROM customer c,
     supplier s,
     lineorder l,
     date_tbl d
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_city = 'UNITED KI1'
  AND s.s_city = 'UNITED KI1'
  AND d.d_year BETWEEN 1992 AND 1997
GROUP BY c.c_city,
         s.s_city,
         d.d_year
ORDER BY d.d_year,
         revenue DESC;

select 'Q4.1' as query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       c.c_nation,
       SUM(l.lo_revenue - l.lo_supplycost) AS profit
FROM date_tbl d,
     customer c,
     supplier s,
     part p,
     lineorder l
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_region = 'AMERICA'
  AND s.s_region = 'AMERICA'
  AND p.p_mfgr = 'MFGR#1'
GROUP BY d.d_year,
         c.c_nation
ORDER BY d.d_year,
         c.c_nation;

select 'Q4.2' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       s.s_nation,
       p.p_category,
       SUM(l.lo_revenue - l.lo_supplycost) AS profit
FROM date_tbl d,
     customer c,
     supplier s,
     part p,
     lineorder l
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_region = 'AMERICA'
  AND s.s_region = 'AMERICA'
  AND (p.p_mfgr = 'MFGR#1' OR p.p_mfgr = 'MFGR#2')
GROUP BY d.d_year,
         s.s_nation,
         p.p_category
ORDER BY d.d_year,
         s.s_nation,
         p.p_category;

select 'Q4.3' as Query;
EXPLAIN (ANALYZE, VERBOSE OFF, COSTS OFF) SELECT d.d_year,
       s.s_city,
       p.p_brand1,
       SUM(l.lo_revenue - l.lo_supplycost) AS profit
FROM date_tbl d,
     customer c,
     supplier s,
     part p,
     lineorder l
WHERE l.lo_custkey = c.c_custkey
  AND l.lo_suppkey = s.s_suppkey
  AND l.lo_partkey = p.p_partkey
  AND l.lo_orderdate = d.d_datekey
  AND c.c_region = 'AMERICA'
  AND s.s_nation = 'UNITED STATES'
  AND (p.p_mfgr = 'MFGR#1' OR p.p_mfgr = 'MFGR#2')
GROUP BY d.d_year,
         s.s_city,
         p.p_brand1
ORDER BY d.d_year,
         s.s_city,
         p.p_brand1;
```

---
Listing the results from SEED 1 queries
---

``` 
 query 
-------
 Q1.1
(1 row)

                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=89.718..89.718 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=8.769..82.518 rows=118598 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=2.107..2.165 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=6.436..49.335 rows=118598 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 137.354 ms
 Execution Time: 92.666 ms
 Peak Memory Usage: 808 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=9.350..9.350 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=7.136..9.086 rows=4301 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.687..2.694 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=4.368..5.198 rows=4301 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.990 ms
 Execution Time: 9.609 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=5.831..5.831 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=5.329..5.769 rows=955 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.566..2.570 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=2.695..2.869 rows=955 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.946 ms
 Execution Time: 6.049 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=234.721..241.775 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=234.685..237.357 rows=44532 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 5016kB
         ->  Hash Join (actual time=20.822..219.138 rows=44532 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=17.642..208.878 rows=44532 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=15.229..184.429 rows=236840 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=6.206..8.395 rows=7883 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=6.171..26.272 rows=59210 loops=4)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.376..2.376 rows=378 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.219..2.323 rows=378 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.151..3.151 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.670..2.890 rows=2556 loops=1)
 Planning Time: 69.543 ms
 Execution Time: 242.319 ms
 Peak Memory Usage: 8189 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=49.640..50.907 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=49.608..49.987 rows=10513 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 1206kB
         ->  Hash Join (actual time=13.822..47.195 rows=10513 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=10.942..42.709 rows=10513 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=8.715..35.930 rows=47572 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.126..1.483 rows=1584 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=6.811..20.378 rows=47572 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.202..2.202 rows=449 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 24kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.021..2.143 rows=449 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.866..2.866 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.419..2.623 rows=2556 loops=1)
 Planning Time: 5.053 ms
 Execution Time: 51.215 ms
 Peak Memory Usage: 3570 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=15.040..15.177 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=15.007..15.055 rows=1277 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 148kB
         ->  Hash Join (actual time=10.876..14.809 rows=1277 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=8.231..11.983 rows=1277 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=5.563..8.716 rows=6569 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=0.614..0.661 rows=216 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=4.748..6.073 rows=6569 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.648..2.648 rows=380 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.510..2.596 rows=380 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.633..2.633 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.179..2.391 rows=2556 loops=1)
 Planning Time: 1.620 ms
 Execution Time: 15.435 ms
 Peak Memory Usage: 1348 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1074.340..1074.345 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=1033.782..1073.252 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=1033.475..1046.377 rows=247638 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: quicksort  Memory: 25491kB
               ->  Hash Join (actual time=16.076..914.173 rows=247638 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=13.117..874.490 rows=271598 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.190..727.779 rows=1347435 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.647..1.766 rows=449 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.237..341.144 rows=1347435 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=5.889..5.889 rows=6051 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 329kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.373..5.064 rows=6051 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=2.946..2.946 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.227..2.707 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 23.761 ms
 Execution Time: 1074.812 ms
 Peak Memory Usage: 33565 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=165.217..165.237 rows=599 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=163.714..164.946 rows=599 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=163.701..164.001 rows=8541 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 1052kB
               ->  Hash Join (actual time=18.458..159.428 rows=8541 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=14.946..154.455 rows=9417 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=5.638..126.301 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.094..1.110 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.434..60.493 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=9.262..9.262 rows=1260 loops=1)
                                 Buckets: 2048  Batches: 1  Memory Usage: 76kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=8.814..9.092 rows=1260 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=3.501..3.501 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.810..3.273 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.612 ms
 Execution Time: 165.538 ms
 Peak Memory Usage: 2814 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1051.442..1051.967 rows=14983 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1555kB
   ->  GroupAggregate (actual time=986.494..1041.867 rows=14983 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=986.477..1009.127 rows=221706 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 23465kB
               ->  Hash Join (actual time=23.681..829.153 rows=221706 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=19.738..791.958 rows=243624 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.264..655.954 rows=1216916 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.165..1.342 rows=405 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.629..307.069 rows=1216916 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=12.441..12.441 rows=5958 loops=1)
                                 Buckets: 8192 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 344kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=10.575..11.785 rows=5958 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.932..3.932 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.656..3.499 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.661 ms
 Execution Time: 1053.126 ms
 Peak Memory Usage: 35024 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=35.181..35.181 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=35.160..35.172 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=35.151..35.154 rows=89 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 31kB
               ->  Hash Join (actual time=19.392..35.127 rows=89 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=15.523..31.226 rows=98 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.186..20.232 rows=26805 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.278..1.282 rows=9 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.834..11.313 rows=26805 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=9.128..9.128 rows=122 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 14kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=9.068..9.097 rows=122 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=3.860..3.860 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=3.161..3.636 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.765 ms
 Execution Time: 35.471 ms
 Peak Memory Usage: 1473 kB
(30 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=826.443..833.174 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=826.178..828.485 rows=45163 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 5065kB
         ->  Hash Join (actual time=37.506..815.716 rows=45163 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=34.661..803.844 rows=45163 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  Hash Join (actual time=28.729..766.982 rows=226254 loops=1)
                           Hash Cond: (l.lo_partkey = p.p_partkey)
                           ->  YB Batched Nested Loop Join (actual time=7.559..570.610 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.555..1.639 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.765..266.576 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=21.040..21.040 rows=40103 loops=1)
                                 Buckets: 65536  Batches: 1  Memory Usage: 1922kB
                                 ->  Index Only Scan using q4_1_p on part p (actual time=3.750..15.306 rows=40103 loops=1)
                                       Index Cond: (p_mfgr = 'MFGR#1'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=5.902..5.902 rows=5992 loops=1)
                           Buckets: 8192  Batches: 1  Memory Usage: 336kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=3.629..5.224 rows=5992 loops=1)
                                 Index Cond: (c_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.836..2.836 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.375..2.588 rows=2556 loops=1)
 Planning Time: 3.500 ms
 Execution Time: 833.590 ms
 Peak Memory Usage: 10799 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=911.773..925.957 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=911.706..915.628 rows=89953 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 10100kB
         ->  Hash Join (actual time=85.227..878.065 rows=89953 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=82.271..860.718 rows=89953 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=13.756..716.158 rows=224890 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=8.131..592.423 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=2.286..2.388 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.574..266.343 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=5.592..5.592 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.627..4.968 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=68.411..68.411 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4464kB
                           ->  Index Scan using part_pkey on part p (actual time=5.927..54.458 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.945..2.945 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.466..2.675 rows=2556 loops=1)
 Planning Time: 2.601 ms
 Execution Time: 926.535 ms
 Peak Memory Usage: 20239 kB
(34 rows)

 query 
-------
 Q4.3
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=262.539..266.254 rows=12797 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=262.529..263.232 rows=17994 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 2174kB
         ->  Hash Join (actual time=90.922..250.992 rows=17994 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=88.010..244.851 rows=17994 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=12.117..153.403 rows=45355 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.060..122.638 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.084..1.101 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.871..57.480 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=6.019..6.019 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.979..5.350 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=75.766..75.766 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4777kB
                           ->  Index Scan using part_pkey on part p (actual time=6.531..60.701 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.901..2.901 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.431..2.636 rows=2556 loops=1)
 Planning Time: 2.487 ms
 Execution Time: 267.176 ms
 Peak Memory Usage: 10475 kB
(33 rows)
```

---
Listing the results from SEED 2 queries
---
```
 query 
-------
 Q1.1
(1 row)

                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=167.087..167.088 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=6.813..152.228 rows=238451 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=0.844..0.905 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=5.738..88.046 rows=238451 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 89.954 ms
 Execution Time: 167.451 ms
 Peak Memory Usage: 808 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=12.652..12.652 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=8.337..12.130 rows=8406 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.568..2.576 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=5.690..7.309 rows=8406 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.879 ms
 Execution Time: 12.877 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=6.580..6.580 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=5.628..6.465 rows=1878 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.568..2.572 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=2.983..3.325 rows=1878 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 1.022 ms
 Execution Time: 6.801 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=645.957..662.297 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=645.886..652.226 rows=97358 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 10679kB
         ->  Hash Join (actual time=21.819..616.802 rows=97358 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=18.258..596.241 rows=97358 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=15.224..544.537 rows=474116 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=6.233..10.891 rows=15897 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=5.710..48.263 rows=59264 loops=8)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.997..2.998 rows=818 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 37kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.465..2.818 rows=818 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.523..3.523 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.697..3.025 rows=2556 loops=1)
 Planning Time: 43.466 ms
 Execution Time: 662.768 ms
 Peak Memory Usage: 13803 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=127.324..129.889 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=127.267..128.100 rows=18993 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 2252kB
         ->  Hash Join (actual time=16.013..122.751 rows=18993 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=13.468..117.026 rows=18993 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=10.626..104.852 rows=94931 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.913..2.553 rows=3151 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=7.433..36.923 rows=47466 loops=2)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.814..2.814 rows=811 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 37kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.502..2.710 rows=811 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.532..2.532 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.108..2.303 rows=2556 loops=1)
 Planning Time: 3.833 ms
 Execution Time: 130.174 ms
 Peak Memory Usage: 4722 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=23.860..24.143 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=23.792..23.909 rows=2550 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 296kB
         ->  Hash Join (actual time=13.182..23.408 rows=2550 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=10.219..20.037 rows=2550 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=7.245..15.739 rows=13155 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=0.950..1.032 rows=402 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=6.051..10.686 rows=13155 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.954..2.954 rows=784 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 36kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.690..2.861 rows=784 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.949..2.949 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.482..2.686 rows=2556 loops=1)
 Planning Time: 1.538 ms
 Execution Time: 24.446 ms
 Peak Memory Usage: 1638 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=2074.249..2074.254 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=1995.783..2074.121 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=1995.187..2023.991 rows=446211 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: quicksort  Memory: 47149kB
               ->  Hash Join (actual time=22.243..1770.400 rows=446211 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=19.007..1696.094 rows=490295 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=8.841..1402.180 rows=2431903 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.951..2.162 rows=811 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.416..656.967 rows=2431903 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=10.136..10.137 rows=12033 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 655kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=5.035..8.628 rows=12033 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=3.224..3.224 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.520..2.975 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 11.510 ms
 Execution Time: 2074.831 ms
 Peak Memory Usage: 57161 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=354.827..354.851 rows=600 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=351.811..354.492 rows=600 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=351.791..352.511 rows=18303 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 2198kB
               ->  Hash Join (actual time=28.070..342.459 rows=18303 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=24.633..335.695 rows=20109 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.511..275.882 rows=489406 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.656..1.691 rows=163 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.700..130.001 rows=489406 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=18.089..18.089 rows=2445 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 147kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=17.280..17.792 rows=2445 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=3.426..3.426 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.658..3.144 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.536 ms
 Execution Time: 355.221 ms
 Peak Memory Usage: 4651 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=2184.378..2184.908 rows=15000 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1556kB
   ->  GroupAggregate (actual time=2046.133..2174.690 rows=15000 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=2046.114..2102.613 rows=432445 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 46073kB
               ->  Hash Join (actual time=35.475..1721.318 rows=432445 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=32.327..1649.458 rows=474948 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=9.159..1354.794 rows=2374248 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.990..2.150 rows=791 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.767..628.926 rows=2374248 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=23.136..23.136 rows=11940 loops=1)
                                 Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 688kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=12.353..21.775 rows=11940 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.137..3.137 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.455..2.916 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.600 ms
 Execution Time: 2186.121 ms
 Peak Memory Usage: 58551 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=63.080..63.080 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=63.049..63.070 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=63.037..63.043 rows=171 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 38kB
               ->  Hash Join (actual time=26.910..62.985 rows=171 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=23.062..59.077 rows=190 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.220..38.049 rows=59806 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.532..1.538 rows=20 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.613..19.325 rows=59806 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=16.778..16.779 rows=208 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 18kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=16.689..16.735 rows=208 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=3.838..3.838 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=3.083..3.576 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.682 ms
 Execution Time: 63.345 ms
 Peak Memory Usage: 1509 kB
(30 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1825.088..1840.257 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=1824.523..1829.807 rows=99244 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 10826kB
         ->  Hash Join (actual time=63.004..1801.650 rows=99244 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=60.397..1778.719 rows=99244 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=19.168..1589.295 rows=493508 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=9.269..1290.771 rows=2453954 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.812..1.994 rows=818 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=7.045..603.636 rows=2453954 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=9.859..9.860 rows=12068 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 676kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=4.559..8.398 rows=12068 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=41.086..41.086 rows=79994 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 3837kB
                           ->  Index Only Scan using q4_1_p on part p (actual time=3.491..30.009 rows=79994 loops=1)
                                 Index Cond: (p_mfgr = 'MFGR#1'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.596..2.597 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.156..2.353 rows=2556 loops=1)
 Planning Time: 3.793 ms
 Execution Time: 1840.671 ms
 Peak Memory Usage: 19988 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=2046.695..2093.197 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=2046.562..2064.734 rows=197646 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 21586kB
         ->  Hash Join (actual time=1733.484..1957.926 rows=197646 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Merge Join (actual time=1730.414..1924.145 rows=197646 loops=1)
                     Merge Cond: (l.lo_partkey = p.p_partkey)
                     ->  Sort (actual time=1724.049..1803.387 rows=493508 loops=1)
                           Sort Key: l.lo_partkey
                           Sort Method: quicksort  Memory: 50844kB
                           ->  Hash Join (actual time=17.966..1592.361 rows=493508 loops=1)
                                 Hash Cond: (l.lo_custkey = c.c_custkey)
                                 ->  YB Batched Nested Loop Join (actual time=9.386..1320.452 rows=2453954 loops=1)
                                       Join Filter: (s.s_suppkey = l.lo_suppkey)
                                       ->  Index Only Scan using q3_1_s on supplier s (actual time=2.057..2.297 rows=818 loops=1)
                                             Index Cond: (s_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                                       ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.830..597.758 rows=2453954 loops=1)
                                             Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                             Heap Fetches: 0
                                 ->  Hash (actual time=8.527..8.527 rows=12068 loops=1)
                                       Buckets: 16384  Batches: 1  Memory Usage: 553kB
                                       ->  Index Only Scan using q3_1_c on customer c (actual time=3.483..7.135 rows=12068 loops=1)
                                             Index Cond: (c_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                     ->  Index Scan using part_pkey on part p (actual time=6.355..27.036 rows=80046 loops=1)
                           Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=3.056..3.057 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.577..2.809 rows=2556 loops=1)
 Planning Time: 2.716 ms
 Execution Time: 2094.022 ms
 Peak Memory Usage: 78674 kB
(35 rows)

 query 
-------
 Q4.3
(1 row)

                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=466.527..475.123 rows=20255 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=466.514..468.677 rows=39624 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 4632kB
         ->  Hash Join (actual time=365.802..437.268 rows=39624 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Merge Join (actual time=362.947..427.169 rows=39624 loops=1)
                     Merge Cond: (l.lo_partkey = p.p_partkey)
                     ->  Sort (actual time=356.721..372.182 rows=98639 loops=1)
                           Sort Key: l.lo_partkey
                           Sort Method: quicksort  Memory: 10779kB
                           ->  Hash Join (actual time=17.081..332.495 rows=98639 loops=1)
                                 Hash Cond: (l.lo_custkey = c.c_custkey)
                                 ->  YB Batched Nested Loop Join (actual time=7.449..267.596 rows=489406 loops=1)
                                       Join Filter: (s.s_suppkey = l.lo_suppkey)
                                       ->  Index Scan using supplier_pkey on supplier s (actual time=1.754..1.791 rows=163 loops=1)
                                             Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                       ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.503..122.548 rows=489406 loops=1)
                                             Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                             Heap Fetches: 0
                                 ->  Hash (actual time=9.586..9.586 rows=12068 loops=1)
                                       Buckets: 16384  Batches: 1  Memory Usage: 553kB
                                       ->  Index Only Scan using q3_1_c on customer c (actual time=3.889..8.163 rows=12068 loops=1)
                                             Index Cond: (c_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                     ->  Index Scan using part_pkey on part p (actual time=6.213..29.375 rows=80046 loops=1)
                           Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.843..2.843 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.337..2.560 rows=2556 loops=1)
 Planning Time: 2.533 ms
 Execution Time: 476.700 ms
 Peak Memory Usage: 19029 kB
(34 rows)
```
---
Listing the results from SEED 3 queries
---
```
 query 
-------
 Q1.1
(1 row)

                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=242.229..242.229 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=8.348..220.562 rows=357647 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=1.862..1.920 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=6.269..126.240 rows=357647 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 72.936 ms
 Execution Time: 242.562 ms
 Peak Memory Usage: 808 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=16.175..16.175 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=8.461..15.386 rows=12694 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.524..2.532 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=5.858..9.559 rows=12694 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.921 ms
 Execution Time: 16.385 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=7.736..7.736 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=6.329..7.567 rows=2820 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.712..2.716 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=3.549..4.072 rows=2820 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.850 ms
 Execution Time: 7.954 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1263.321..1288.067 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=1263.219..1272.994 rows=148684 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 17760kB
         ->  Hash Join (actual time=27.948..1217.744 rows=148684 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=24.813..1189.853 rows=148684 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=21.443..1114.772 rows=715321 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=5.978..10.425 rows=15897 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=11.742..111.380 rows=89415 loops=8)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=3.312..3.312 rows=1246 loops=1)
                           Buckets: 2048  Batches: 1  Memory Usage: 60kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.895..3.173 rows=1246 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.083..3.083 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.595..2.811 rows=2556 loops=1)
 Planning Time: 47.889 ms
 Execution Time: 1288.539 ms
 Peak Memory Usage: 24829 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=210.145..214.238 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=210.055..211.476 rows=29004 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 3034kB
         ->  Hash Join (actual time=18.279..203.184 rows=29004 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=15.431..195.412 rows=29004 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=12.423..178.221 rows=142421 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.767..2.436 rows=3151 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=9.470..66.810 rows=71210 loops=2)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.988..2.988 rows=1227 loops=1)
                           Buckets: 2048  Batches: 1  Memory Usage: 60kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.177..2.743 rows=1227 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.829..2.830 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.160..2.427 rows=2556 loops=1)
 Planning Time: 5.805 ms
 Execution Time: 214.597 ms
 Peak Memory Usage: 6693 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=33.464..33.871 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=33.365..33.535 rows=3429 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 364kB
         ->  Hash Join (actual time=15.151..32.866 rows=3429 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=12.690..29.901 rows=3429 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=10.065..25.574 rows=17712 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=0.810..0.892 rows=402 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=9.007..19.604 rows=17712 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.588..2.588 rows=1162 loops=1)
                           Buckets: 2048  Batches: 1  Memory Usage: 57kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.167..2.456 rows=1162 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.445..2.445 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.997..2.193 rows=2556 loops=1)
 Planning Time: 1.603 ms
 Execution Time: 34.190 ms
 Peak Memory Usage: 1964 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=3018.638..3018.643 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=2874.565..3018.537 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=2873.465..2945.502 rows=673241 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: external merge  Disk: 21768kB
               ->  Hash Join (actual time=29.619..2498.052 rows=673241 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=25.906..2395.677 rows=739515 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=10.490..1963.570 rows=3681230 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=2.343..2.663 rows=1227 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=7.493..918.069 rows=3681230 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=15.356..15.356 rows=18033 loops=1)
                                 Buckets: 32768  Batches: 1  Memory Usage: 1046kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=7.222..13.078 rows=18033 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=3.699..3.699 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=3.040..3.478 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 23.882 ms
 Execution Time: 3020.429 ms
 Peak Memory Usage: 77700 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=507.203..507.222 rows=600 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=502.717..506.908 rows=600 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=502.696..503.955 rows=27281 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 2900kB
               ->  Hash Join (actual time=36.711..488.792 rows=27281 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=33.585..481.254 rows=29964 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=8.188..393.924 rows=733070 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=2.053..2.115 rows=245 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.920..184.310 rows=733070 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=25.372..25.372 rows=3629 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 203kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=24.268..24.996 rows=3629 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=3.114..3.115 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.432..2.876 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.555 ms
 Execution Time: 507.566 ms
 Peak Memory Usage: 6931 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=3087.570..3088.112 rows=15000 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1556kB
   ->  GroupAggregate (actual time=2964.696..3078.447 rows=15000 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=2964.678..3008.460 rows=646259 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: external merge  Disk: 26568kB
               ->  Hash Join (actual time=46.905..2402.742 rows=646259 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=43.337..2304.043 rows=709625 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=10.588..1877.379 rows=3538883 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=2.784..3.042 rows=1180 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=7.225..876.073 rows=3538883 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=32.725..32.726 rows=17949 loops=1)
                                 Buckets: 32768 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 1098kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=12.365..30.805 rows=17949 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.557..3.558 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.872..3.316 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.524 ms
 Execution Time: 3090.841 ms
 Peak Memory Usage: 77189 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=86.922..86.922 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=86.877..86.912 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=86.860..86.871 rows=294 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 47kB
               ->  Hash Join (actual time=35.009..86.779 rows=294 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=31.533..83.197 rows=317 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.305..52.869 rows=87242 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=2.179..2.187 rows=29 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.043..26.127 rows=87242 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=24.120..24.121 rows=330 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 24kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=23.991..24.061 rows=330 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=3.466..3.466 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.801..3.246 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.639 ms
 Execution Time: 87.177 ms
 Peak Memory Usage: 1525 kB
(30 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=2778.342..2801.009 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=2777.729..2785.680 rows=149799 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 17848kB
         ->  Hash Join (actual time=66.155..2742.025 rows=149799 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=63.640..2711.374 rows=149799 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  Hash Join (actual time=50.294..2557.798 rows=747445 loops=1)
                           Hash Cond: (l.lo_partkey = p.p_partkey)
                           ->  YB Batched Nested Loop Join (actual time=9.826..1858.384 rows=3738260 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.866..2.157 rows=1246 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=7.336..869.398 rows=3738260 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=40.097..40.097 rows=79994 loops=1)
                                 Buckets: 131072  Batches: 1  Memory Usage: 3837kB
                                 ->  Index Only Scan using q4_1_p on part p (actual time=4.767..28.208 rows=79994 loops=1)
                                       Index Cond: (p_mfgr = 'MFGR#1'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=13.311..13.311 rows=18012 loops=1)
                           Buckets: 32768  Batches: 1  Memory Usage: 1073kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=4.508..11.021 rows=18012 loops=1)
                                 Index Cond: (c_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.504..2.504 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.059..2.265 rows=2556 loops=1)
 Planning Time: 4.077 ms
 Execution Time: 2801.467 ms
 Peak Memory Usage: 32891 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=2943.823..2997.367 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=2943.638..2960.835 rows=299569 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 35692kB
         ->  Hash Join (actual time=162.015..2827.277 rows=299569 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=159.053..2776.054 rows=299569 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=19.588..2372.990 rows=750198 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=9.625..1925.926 rows=3738260 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=2.006..2.341 rows=1246 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.928..869.295 rows=3738260 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=9.919..9.919 rows=18012 loops=1)
                                 Buckets: 32768  Batches: 1  Memory Usage: 890kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.265..8.001 rows=18012 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=139.061..139.061 rows=159946 loops=1)
                           Buckets: 262144  Batches: 1  Memory Usage: 8921kB
                           ->  Index Scan using part_pkey on part p (actual time=5.992..110.684 rows=159946 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.950..2.950 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.487..2.703 rows=2556 loops=1)
 Planning Time: 2.552 ms
 Execution Time: 2997.924 ms
 Peak Memory Usage: 53482 kB
(34 rows)

 query 
-------
 Q4.3
(1 row)

                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=719.020..730.260 rows=23939 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=719.009..721.692 rows=58734 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 6125kB
         ->  Hash Join (actual time=160.730..678.593 rows=58734 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=157.758..666.060 rows=58734 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=17.971..475.655 rows=147605 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.344..380.501 rows=733070 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=2.096..2.149 rows=245 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.049..171.562 rows=733070 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=10.580..10.580 rows=18012 loops=1)
                                 Buckets: 32768  Batches: 1  Memory Usage: 890kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.477..8.518 rows=18012 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=139.248..139.248 rows=159946 loops=1)
                           Buckets: 262144  Batches: 1  Memory Usage: 9546kB
                           ->  Index Scan using part_pkey on part p (actual time=6.070..110.604 rows=159946 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.962..2.962 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.519..2.717 rows=2556 loops=1)
 Planning Time: 2.445 ms
 Execution Time: 731.792 ms
 Peak Memory Usage: 24486 kB
(33 rows)


```
---
Listing the results from SEED 10 queries
---
```
 query 
-------
 Q1.1
(1 row)

                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=622.903..622.903 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=5.349..548.793 rows=1193001 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=1.508..1.565 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=3.635..233.266 rows=1193001 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 124.422 ms
 Execution Time: 624.490 ms
 Peak Memory Usage: 808 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=28.351..28.351 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=5.070..25.545 rows=42209 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.716..2.723 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=2.278..10.922 rows=42209 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.972 ms
 Execution Time: 28.833 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=11.837..11.837 rows=1 loops=1)
   ->  Nested Loop (actual time=3.319..11.237 rows=9488 loops=1)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.638..2.648 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=0.854..1.099 rows=1355 loops=7)
               Index Cond: ((lo_orderdate = d.d_datekey) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.351 ms
 Execution Time: 11.895 ms
 Peak Memory Usage: 56 kB
(10 rows)

 query 
-------
 Q2.1
(1 row)

                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1915.717..2060.245 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=1915.193..1989.769 rows=490740 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 50628kB
         ->  Hash Join (actual time=21.685..1741.218 rows=490740 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=18.310..1660.402 rows=490740 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=13.710..1406.543 rows=2394017 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=6.188..15.298 rows=31882 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=4.570..43.543 rows=149626 loops=16)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=4.549..4.549 rows=4102 loops=1)
                           Buckets: 8192  Batches: 1  Memory Usage: 209kB
                           ->  Index Only Scan using q2_1_s on supplier s (actual time=3.232..4.116 rows=4102 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.342..3.342 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.857..3.067 rows=2556 loops=1)
 Planning Time: 59.990 ms
 Execution Time: 2060.876 ms
 Peak Memory Usage: 56161 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                         
---------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=411.326..428.385 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=411.069..418.331 rows=94856 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 10483kB
         ->  Hash Join (actual time=17.808..388.909 rows=94856 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=14.561..370.439 rows=94856 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=10.181..315.688 rows=477123 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=4.385..5.734 rows=6409 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=4.696..42.716 rows=119281 loops=4)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=4.347..4.347 rows=4001 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 173kB
                           ->  Index Only Scan using q2_1_s on supplier s (actual time=3.101..3.947 rows=4001 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.238..3.238 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.763..2.972 rows=2556 loops=1)
 Planning Time: 5.283 ms
 Execution Time: 428.769 ms
 Peak Memory Usage: 13770 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=63.124..64.851 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=62.688..63.636 rows=11654 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 1295kB
         ->  Hash Join (actual time=13.037..61.147 rows=11654 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=10.636..56.843 rows=11654 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=6.242..46.298 rows=58800 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.804..1.974 rows=794 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=4.009..27.336 rows=58800 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=4.368..4.368 rows=3972 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 172kB
                           ->  Index Only Scan using q2_1_s on supplier s (actual time=3.101..3.946 rows=3972 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.389..2.389 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.935..2.136 rows=2556 loops=1)
 Planning Time: 1.492 ms
 Execution Time: 65.119 ms
 Peak Memory Usage: 3233 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=9663.972..9663.977 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  HashAggregate (actual time=9662.558..9662.592 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Hash Join (actual time=48.545..9244.577 rows=2199936 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=45.147..8912.272 rows=2414598 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  YB Batched Nested Loop Join (actual time=11.557..6475.949 rows=12003471 loops=1)
                           Join Filter: (s.s_suppkey = l.lo_suppkey)
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.778..3.853 rows=4001 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.998..1022.506 rows=4001157 loops=3)
                                 Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=33.512..33.512 rows=60535 loops=1)
                           Buckets: 65536  Batches: 1  Memory Usage: 3162kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=3.422..24.474 rows=60535 loops=1)
                                 Index Cond: (c_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.377..3.378 rows=2192 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 118kB
                     ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.662..3.145 rows=2192 loops=1)
                           Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 20.994 ms
 Execution Time: 9664.463 ms
 Peak Memory Usage: 8434 kB
(29 rows)

 query 
-------
 Q3.2
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1666.550..1666.569 rows=600 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=1650.741..1666.238 rows=600 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=1650.699..1656.196 rows=87646 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 9920kB
               ->  Hash Join (actual time=98.105..1605.029 rows=87646 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=94.625..1585.118 rows=96180 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=12.351..1285.469 rows=2426825 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=5.819..5.983 rows=809 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.091..598.405 rows=2426825 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=82.217..82.217 rows=11913 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 687kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=46.915..80.665 rows=11913 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=3.466..3.466 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.773..3.231 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.641 ms
 Execution Time: 1667.027 ms
 Peak Memory Usage: 14753 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=12083.609..12084.159 rows=15000 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1556kB
   ->  GroupAggregate (actual time=11434.174..12074.226 rows=15000 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=11434.128..11833.039 rows=2191339 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: external merge  Disk: 90064kB
               ->  Hash Join (actual time=127.275..9436.947 rows=2191339 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=123.587..9090.701 rows=2404966 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=16.442..6469.419 rows=12029929 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=7.596..8.450 rows=4010 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.698..1018.131 rows=4009976 loops=3)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=107.103..107.103 rows=60067 loops=1)
                                 Buckets: 65536 (originally 2048)  Batches: 1 (originally 1)  Memory Usage: 3328kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=12.461..99.351 rows=60067 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.674..3.674 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.972..3.443 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.533 ms
 Execution Time: 12091.076 ms
 Peak Memory Usage: 81316 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=245.200..245.201 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=245.064..245.191 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=245.018..245.067 rows=961 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 100kB
               ->  Hash Join (actual time=92.355..244.786 rows=961 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=89.009..241.054 rows=1071 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=11.011..143.695 rows=251672 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=5.828..5.848 rows=84 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.045..66.898 rows=251672 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=77.949..77.949 rows=1206 loops=1)
                                 Buckets: 2048  Batches: 1  Memory Usage: 73kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=77.509..77.775 rows=1206 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=3.335..3.335 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.632..3.077 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.541 ms
 Execution Time: 245.466 ms
 Peak Memory Usage: 1690 kB
(30 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=10767.233..10885.967 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=10763.459..10820.883 rows=489033 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 50494kB
         ->  Hash Join (actual time=112.928..10647.565 rows=489033 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=109.997..10519.917 rows=489033 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  Hash Join (actual time=76.614..9681.282 rows=2460302 loops=1)
                           Hash Cond: (l.lo_partkey = p.p_partkey)
                           ->  YB Batched Nested Loop Join (actual time=12.043..6155.358 rows=12301507 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q2_1_s on supplier s (actual time=2.703..3.599 rows=4102 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.941..970.005 rows=4100502 loops=3)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=63.812..63.812 rows=160027 loops=1)
                                 Buckets: 262144  Batches: 1  Memory Usage: 7674kB
                                 ->  Index Only Scan using q4_1_p on part p (actual time=2.192..36.660 rows=160027 loops=1)
                                       Index Cond: (p_mfgr = 'MFGR#1'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=33.278..33.278 rows=59761 loops=1)
                           Buckets: 65536  Batches: 1  Memory Usage: 3220kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=4.295..25.082 rows=59761 loops=1)
                                 Index Cond: (c_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.920..2.920 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.467..2.669 rows=2556 loops=1)
 Planning Time: 3.592 ms
 Execution Time: 10886.738 ms
 Peak Memory Usage: 72203 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                             QUERY PLAN                                                              
-------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=11689.489..11895.953 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=11688.792..11780.270 rows=976694 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: external merge  Disk: 38616kB
         ->  Hash Join (actual time=319.662..11195.783 rows=976694 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=316.566..10996.529 rows=976694 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=43.130..9781.165 rows=2441506 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=11.944..7022.402 rows=12301507 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=3.114..4.321 rows=4102 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.750..1069.199 rows=4100502 loops=3)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=31.108..31.109 rows=59761 loops=1)
                                 Buckets: 65536  Batches: 1  Memory Usage: 2613kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.910..23.490 rows=59761 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=272.634..272.634 rows=319771 loops=1)
                           Buckets: 524288  Batches: 1  Memory Usage: 17837kB
                           ->  Index Scan using part_pkey on part p (actual time=6.349..203.670 rows=319771 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=3.084..3.084 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.619..2.821 rows=2556 loops=1)
 Planning Time: 2.568 ms
 Execution Time: 11899.196 ms
 Peak Memory Usage: 103780 kB
(34 rows)

 query 
-------
 Q4.3
(1 row)

                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=2368.268..2431.587 rows=27911 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=2368.248..2394.898 rows=192379 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 21174kB
         ->  Hash Join (actual time=1944.864..2210.168 rows=192379 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Merge Join (actual time=1941.962..2177.348 rows=192379 loops=1)
                     Merge Cond: (l.lo_partkey = p.p_partkey)
                     ->  Sort (actual time=1935.541..2012.918 rows=481311 loops=1)
                           Sort Key: l.lo_partkey
                           Sort Method: quicksort  Memory: 49891kB
                           ->  Hash Join (actual time=43.515..1809.886 rows=481311 loops=1)
                                 Hash Cond: (l.lo_custkey = c.c_custkey)
                                 ->  YB Batched Nested Loop Join (actual time=13.056..1289.549 rows=2426825 loops=1)
                                       Join Filter: (s.s_suppkey = l.lo_suppkey)
                                       ->  Index Scan using supplier_pkey on supplier s (actual time=6.402..6.567 rows=809 loops=1)
                                             Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                       ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.221..582.892 rows=2426825 loops=1)
                                             Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                             Heap Fetches: 0
                                 ->  Hash (actual time=30.368..30.369 rows=59761 loops=1)
                                       Buckets: 65536  Batches: 1  Memory Usage: 2613kB
                                       ->  Index Only Scan using q3_1_c on customer c (actual time=3.284..22.716 rows=59761 loops=1)
                                             Index Cond: (c_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                     ->  Index Scan using part_pkey on part p (actual time=6.410..63.118 rows=239868 loops=1)
                           Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=2.888..2.888 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.424..2.630 rows=2556 loops=1)
 Planning Time: 2.536 ms
 Execution Time: 2433.805 ms
 Peak Memory Usage: 81387 kB
(34 rows)
```