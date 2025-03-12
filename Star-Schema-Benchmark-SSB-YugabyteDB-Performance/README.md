# Running SSB (Star Schema Benchmark) on YugabyteDB

Summary Of Great Performance Results:

Here’s the revised table clearly referencing the fact table size (lineorder table row counts) and converting Seed 10 execution times into seconds, as requested:

Query	Seed 1 (6 million rows)	Seed 2 (11.9 million rows)	Seed 3 (17.9 million rows)	Seed 10 (59.9 million rows)
Q1.1	267 ms	296 ms	242 ms	0.624 sec
Q1.2	13 ms	14 ms	16 ms	0.028 sec
Q1.3	7 ms	6 ms	7 ms	0.011 sec
Q2.1	810 ms	805 ms	1288 ms	2.060 sec
Q2.2	160 ms	169 ms	214 ms	0.428 sec
Q2.3	27 ms	27 ms	34 ms	0.065 sec
Q3.1	2115 ms	2115 ms	3020 ms	9.664 sec
Q3.2	354 ms	355 ms	507 ms	1.667 sec
Q3.3	2222 ms	2223 ms	3090 ms	12.091 sec
Q3.4	69 ms	69 ms	87 ms	0.245 sec
Q4.1	1854 ms	1854 ms	2801 ms	10.886 sec
Q4.2	2121 ms	2121 ms	2997 ms	11.899 sec
Q4.3	485 ms	485 ms	731 ms	2.433 sec

This repository contains the schema definitions, indexing, data creation, data-loading, and performance execution plans for running the Star Schema Benchmark (SSB) on YugabyteDB's YSQL (PostgreSQL) Query Layer.

The executions were performed on a 3 node, RF3 cluster with fault tolerance to be able to completely lose one availability zone in a public cloud and continue running.

Because I started with just the data-gen and the table schema, the Indexes are a work in progress. I just indexed to the point of reasonable result and plan to return back to optimise further.


Performance Summary:

Queries demonstrate good execution times and optimized execution plans, showing YugabyteDB's distributed cost based optimiser achieves the same execution strategies as the relevant postgres version.

Overall, the benchmark highlights YugabyteDB's strong performance, especially in distributed JOIN and aggregation workloads, making it suitable for financial reporting similar to SSB, which often comes hand in hand with an OLTP system.  This is a common ask for an entire business moving all of their databases to YugabyteDB.

This repository provides a complete, reproducible example for developers aiming to benchmark or optimize query performance on YugabyteDB.

Please contribute if you would like to improve the indexing or run the benchmark on later version, or with more nodes and a large seeded dataset. Otherwise i will come back to the latter part and run this later with larger seed data. 

Note that I used YugabyteDB 2024.2.0 which is the base release of the latest stable. Master or preview branch is likely to improve further. Will test the same 

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
export PGPASSWORD="Yuga2021PoC!"
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
export PGPASSWORD="Yuga2021PoC!"
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
export PGPASSWORD="Yuga2021PoC!"
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
export PGPASSWORD="Yuga2021PoC!"
ysqlsh -h 10.0.0.61 -c "\i schema_and_data.sql"
ysqlsh -h 10.0.0.61 -c "\i querieswithexplain.sql" > querieswithexplain2024.2_results_SEED_10_new.txt
```


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
 Aggregate (actual time=87.458..87.459 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=9.289..80.183 rows=118598 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=2.288..2.348 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=6.770..46.734 rows=118598 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 133.564 ms
 Execution Time: 90.058 ms
 Peak Memory Usage: 690 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=9.594..9.594 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=7.401..9.329 rows=4301 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.638..2.646 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=4.709..5.524 rows=4301 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.621 ms
 Execution Time: 9.754 ms
 Peak Memory Usage: 476 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=5.214..5.214 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=4.737..5.153 rows=955 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.301..2.304 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=2.391..2.563 rows=955 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.643 ms
 Execution Time: 5.406 ms
 Peak Memory Usage: 476 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=260.117..267.195 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=260.083..262.742 rows=44532 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 5016kB
         ->  Hash Join (actual time=20.132..244.323 rows=44532 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=16.287..233.463 rows=44532 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=13.910..209.233 rows=236840 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=5.672..7.892 rows=7883 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=6.240..16.396 rows=29605 loops=8)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.348..2.349 rows=378 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.211..2.298 rows=378 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.820..3.820 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=3.333..3.555 rows=2556 loops=1)
 Planning Time: 83.252 ms
 Execution Time: 267.615 ms
 Peak Memory Usage: 7815 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=63.602..64.928 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=63.569..63.941 rows=10513 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 1206kB
         ->  Hash Join (actual time=14.401..61.387 rows=10513 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=11.769..57.141 rows=10513 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=9.616..50.419 rows=47572 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.180..1.512 rows=1584 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=7.210..17.450 rows=23786 loops=2)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.132..2.132 rows=449 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 24kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=1.973..2.075 rows=449 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.618..2.618 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.151..2.361 rows=2556 loops=1)
 Planning Time: 5.201 ms
 Execution Time: 65.206 ms
 Peak Memory Usage: 2955 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=15.200..15.345 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=15.168..15.213 rows=1277 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 148kB
         ->  Hash Join (actual time=10.641..14.978 rows=1277 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=7.108..11.252 rows=1277 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=4.211..7.734 rows=6569 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=0.563..0.608 rows=216 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=3.513..5.185 rows=6569 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.861..2.861 rows=380 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.705..2.796 rows=380 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.519..3.520 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=3.047..3.271 rows=2556 loops=1)
 Planning Time: 1.204 ms
 Execution Time: 15.551 ms
 Peak Memory Usage: 1212 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1076.004..1076.009 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=1036.327..1074.685 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=1036.054..1048.239 rows=247638 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: quicksort  Memory: 25491kB
               ->  Hash Join (actual time=16.293..918.102 rows=247638 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=12.761..875.612 rows=271598 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.341..732.369 rows=1347435 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.935..2.054 rows=449 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.121..342.573 rows=1347435 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=5.387..5.387 rows=6051 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 329kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=2.976..4.615 rows=6051 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=3.518..3.518 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.836..3.292 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 29.876 ms
 Execution Time: 1076.451 ms
 Peak Memory Usage: 33050 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=167.041..167.061 rows=599 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=165.547..166.774 rows=599 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=165.533..165.826 rows=8541 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 1052kB
               ->  Hash Join (actual time=18.745..161.255 rows=8541 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=15.451..156.376 rows=9417 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=5.650..127.760 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.147..1.165 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.400..61.173 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=9.751..9.751 rows=1260 loops=1)
                                 Buckets: 2048  Batches: 1  Memory Usage: 76kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=9.312..9.598 rows=1260 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=3.282..3.282 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.616..3.061 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.320 ms
 Execution Time: 167.334 ms
 Peak Memory Usage: 2714 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1708.878..1709.404 rows=14983 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1555kB
   ->  GroupAggregate (actual time=1652.559..1699.161 rows=14983 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=1652.543..1670.054 rows=221706 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 23465kB
               ->  Hash Join (actual time=19.883..1494.924 rows=221706 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=16.264..1448.099 rows=243624 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  Nested Loop (actual time=3.178..1278.063 rows=1216916 loops=1)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.141..2.006 rows=405 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.166..2.865 rows=3005 loops=405)
                                       Index Cond: (lo_suppkey = s.s_suppkey)
                                       Heap Fetches: 0
                           ->  Hash (actual time=13.063..13.063 rows=5958 loops=1)
                                 Buckets: 8192 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 344kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=11.168..12.397 rows=5958 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.608..3.608 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.915..3.359 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 0.963 ms
 Execution Time: 1710.435 ms
 Peak Memory Usage: 33940 kB
(29 rows)

 query 
-------
 Q3.4
(1 row)

                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=45.068..45.069 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=45.047..45.059 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=45.038..45.041 rows=89 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 31kB
               ->  Hash Join (actual time=15.981..44.992 rows=89 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=12.408..41.377 rows=98 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  Nested Loop (actual time=3.820..31.014 rows=26805 loops=1)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.181..1.198 rows=9 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.352..3.026 rows=2978 loops=9)
                                       Index Cond: (lo_suppkey = s.s_suppkey)
                                       Heap Fetches: 0
                           ->  Hash (actual time=8.549..8.550 rows=122 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 14kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=8.493..8.521 rows=122 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=3.563..3.563 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.863..3.335 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.098 ms
 Execution Time: 45.149 ms
 Peak Memory Usage: 520 kB
(29 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=788.512..795.365 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=788.250..790.649 rows=45163 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 5065kB
         ->  Hash Join (actual time=39.182..777.160 rows=45163 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=36.237..766.001 rows=45163 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  Hash Join (actual time=30.497..731.980 rows=226254 loops=1)
                           Hash Cond: (l.lo_partkey = p.p_partkey)
                           ->  YB Batched Nested Loop Join (actual time=8.709..563.609 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=2.011..2.100 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=6.457..262.516 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=21.710..21.711 rows=40103 loops=1)
                                 Buckets: 65536  Batches: 1  Memory Usage: 1922kB
                                 ->  Index Only Scan using q4_1_p on part p (actual time=4.306..16.664 rows=40103 loops=1)
                                       Index Cond: (p_mfgr = 'MFGR#1'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=5.709..5.709 rows=5992 loops=1)
                           Buckets: 8192  Batches: 1  Memory Usage: 336kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=3.373..5.013 rows=5992 loops=1)
                                 Index Cond: (c_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=2.937..2.937 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.454..2.655 rows=2556 loops=1)
 Planning Time: 4.778 ms
 Execution Time: 795.791 ms
 Peak Memory Usage: 10699 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=899.865..914.029 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=899.795..903.732 rows=89953 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 10100kB
         ->  Hash Join (actual time=87.632..865.634 rows=89953 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=84.437..848.156 rows=89953 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=11.991..704.874 rows=224890 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=7.306..584.381 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=2.020..2.122 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=5.044..262.296 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=4.647..4.648 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=2.589..3.998 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=72.113..72.113 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4464kB
                           ->  Index Scan using part_pkey on part p (actual time=6.249..60.092 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=3.184..3.184 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.699..2.908 rows=2556 loops=1)
 Planning Time: 2.417 ms
 Execution Time: 914.612 ms
 Peak Memory Usage: 20138 kB
(34 rows)

 query 
-------
 Q4.3
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=262.229..265.900 rows=12797 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=262.219..262.927 rows=17994 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 2174kB
         ->  Hash Join (actual time=92.704..250.560 rows=17994 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=89.546..244.333 rows=17994 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=11.299..152.203 rows=45355 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=5.748..122.773 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.213..1.233 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.434..56.963 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=5.518..5.519 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=3.550..4.902 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=78.011..78.011 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4777kB
                           ->  Index Scan using part_pkey on part p (actual time=6.938..65.822 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=3.140..3.140 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.683..2.889 rows=2556 loops=1)
 Planning Time: 2.273 ms
 Execution Time: 266.823 ms
 Peak Memory Usage: 10375 kB
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
 Aggregate (actual time=293.488..293.488 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=6.596..278.537 rows=238451 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=1.794..1.852 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=4.581..212.824 rows=238451 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 139.810 ms
 Execution Time: 296.542 ms
 Peak Memory Usage: 808 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=14.720..14.721 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=5.730..14.198 rows=8406 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.501..2.510 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=3.128..9.333 rows=8406 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.884 ms
 Execution Time: 14.922 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=5.503..5.504 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=4.547..5.387 rows=1878 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.527..2.530 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=1.951..2.295 rows=1878 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1999])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.883 ms
 Execution Time: 6.032 ms
 Peak Memory Usage: 612 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=789.522..805.526 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=789.452..795.668 rows=97358 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 10679kB
         ->  Hash Join (actual time=18.586..758.312 rows=97358 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=12.938..733.902 rows=97358 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=10.314..680.775 rows=474116 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=3.153..8.113 rows=15897 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=2.391..65.294 rows=59264 loops=8)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.585..2.586 rows=818 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 37kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.311..2.491 rows=818 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=5.623..5.623 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=3.189..5.301 rows=2556 loops=1)
 Planning Time: 44.232 ms
 Execution Time: 805.985 ms
 Peak Memory Usage: 13763 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=166.344..168.832 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=166.291..167.032 rows=18993 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 2252kB
         ->  Hash Join (actual time=15.717..161.979 rows=18993 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=11.449..153.918 rows=18993 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=8.331..140.585 rows=94931 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=2.661..3.381 rows=3151 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=4.073..53.237 rows=47466 loops=2)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=3.101..3.102 rows=811 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 37kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.831..3.011 rows=811 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=4.254..4.254 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.835..3.967 rows=2556 loops=1)
 Planning Time: 4.730 ms
 Execution Time: 169.173 ms
 Peak Memory Usage: 4617 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=27.368..27.661 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=27.304..27.422 rows=2550 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 296kB
         ->  Hash Join (actual time=13.806..26.925 rows=2550 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=9.023..21.732 rows=2550 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=6.177..17.601 rows=13155 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=2.259..2.347 rows=402 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=3.637..11.282 rows=13155 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1999]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=2.827..2.827 rows=784 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 36kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=2.570..2.742 rows=784 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=4.770..4.770 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.469..4.509 rows=2556 loops=1)
 Planning Time: 1.577 ms
 Execution Time: 27.909 ms
 Peak Memory Usage: 1625 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=2114.618..2114.623 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=2038.075..2113.814 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=2037.529..2064.250 rows=446211 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: quicksort  Memory: 47149kB
               ->  Hash Join (actual time=26.969..1808.449 rows=446211 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=22.188..1731.386 rows=490295 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.925..1423.615 rows=2431903 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.916..2.142 rows=811 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.534..677.814 rows=2431903 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=15.225..15.225 rows=12033 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 655kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=1.865..13.611 rows=12033 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=4.765..4.765 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.733..4.542 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 17.205 ms
 Execution Time: 2115.247 ms
 Peak Memory Usage: 57097 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                             
-----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=354.583..354.603 rows=600 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=351.480..354.278 rows=600 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=351.461..352.237 rows=18303 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 2198kB
               ->  Hash Join (actual time=31.197..342.201 rows=18303 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=25.840..333.645 rows=20109 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=4.883..271.891 rows=489406 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.607..1.641 rows=163 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=3.131..128.296 rows=489406 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=20.922..20.923 rows=2445 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 147kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=16.506..20.591 rows=2445 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=5.348..5.349 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=3.078..5.105 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.532 ms
 Execution Time: 354.964 ms
 Peak Memory Usage: 4619 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=2221.161..2221.685 rows=15000 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1556kB
   ->  GroupAggregate (actual time=2086.385..2211.620 rows=15000 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=2086.367..2141.119 rows=432445 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 46073kB
               ->  Hash Join (actual time=37.597..1768.953 rows=432445 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=33.782..1695.448 rows=474948 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.476..1388.582 rows=2374248 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.697..1.857 rows=791 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.386..669.312 rows=2374248 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=27.278..27.279 rows=11940 loops=1)
                                 Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 688kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=4.841..25.919 rows=11940 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=3.807..3.807 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.337..3.543 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.595 ms
 Execution Time: 2222.990 ms
 Peak Memory Usage: 59004 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=68.986..68.986 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=68.955..68.977 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=68.941..68.949 rows=171 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 38kB
               ->  Hash Join (actual time=29.447..68.879 rows=171 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=24.369..63.727 rows=190 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=4.460..39.542 rows=59806 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.629..1.635 rows=20 loops=1)
                                       Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.744..20.261 rows=59806 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=19.842..19.842 rows=208 loops=1)
                                 Buckets: 1024  Batches: 1  Memory Usage: 18kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=19.745..19.794 rows=208 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                     ->  Hash (actual time=5.069..5.069 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.825..4.807 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.635 ms
 Execution Time: 69.231 ms
 Peak Memory Usage: 1222 kB
(30 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1838.468..1853.688 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=1837.949..1843.370 rows=99244 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 10826kB
         ->  Hash Join (actual time=58.899..1814.332 rows=99244 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=55.810..1791.906 rows=99244 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=22.444..1620.797 rows=493508 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=6.296..1313.727 rows=2453954 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=1.321..1.525 rows=818 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.508..625.537 rows=2453954 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=16.104..16.105 rows=12068 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 676kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=2.311..14.485 rows=12068 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=33.230..33.230 rows=79994 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 3837kB
                           ->  Index Only Scan using q4_1_p on part p (actual time=0.922..22.163 rows=79994 loops=1)
                                 Index Cond: (p_mfgr = 'MFGR#1'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=3.080..3.080 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.604..2.842 rows=2556 loops=1)
 Planning Time: 2.974 ms
 Execution Time: 1854.221 ms
 Peak Memory Usage: 19853 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=2082.729..2120.984 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=2082.609..2096.186 rows=197646 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 21586kB
         ->  Hash Join (actual time=1780.027..2000.320 rows=197646 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Merge Join (actual time=1775.552..1965.750 rows=197646 loops=1)
                     Merge Cond: (l.lo_partkey = p.p_partkey)
                     ->  Sort (actual time=1772.892..1850.937 rows=493508 loops=1)
                           Sort Key: l.lo_partkey
                           Sort Method: quicksort  Memory: 50844kB
                           ->  Hash Join (actual time=22.328..1640.372 rows=493508 loops=1)
                                 Hash Cond: (l.lo_custkey = c.c_custkey)
                                 ->  YB Batched Nested Loop Join (actual time=6.915..1347.657 rows=2453954 loops=1)
                                       Join Filter: (s.s_suppkey = l.lo_suppkey)
                                       ->  Index Only Scan using q3_1_s on supplier s (actual time=2.088..2.305 rows=818 loops=1)
                                             Index Cond: (s_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                                       ->  Index Only Scan using q4_1_2l on lineorder l (actual time=4.362..623.772 rows=2453954 loops=1)
                                             Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                             Heap Fetches: 0
                                 ->  Hash (actual time=15.380..15.380 rows=12068 loops=1)
                                       Buckets: 16384  Batches: 1  Memory Usage: 553kB
                                       ->  Index Only Scan using q3_1_c on customer c (actual time=2.159..13.919 rows=12068 loops=1)
                                             Index Cond: (c_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                     ->  Index Scan using part_pkey on part p (actual time=2.651..23.037 rows=80046 loops=1)
                           Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=4.461..4.461 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.781..4.201 rows=2556 loops=1)
 Planning Time: 2.715 ms
 Execution Time: 2121.809 ms
 Peak Memory Usage: 79139 kB
(35 rows)

 query 
-------
 Q4.3
(1 row)

                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=474.884..483.552 rows=20255 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=474.873..477.097 rows=39624 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 4632kB
         ->  Hash Join (actual time=369.458..446.416 rows=39624 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Merge Join (actual time=364.795..435.274 rows=39624 loops=1)
                     Merge Cond: (l.lo_partkey = p.p_partkey)
                     ->  Sort (actual time=362.308..377.667 rows=98639 loops=1)
                           Sort Key: l.lo_partkey
                           Sort Method: quicksort  Memory: 10779kB
                           ->  Hash Join (actual time=21.941..337.427 rows=98639 loops=1)
                                 Hash Cond: (l.lo_custkey = c.c_custkey)
                                 ->  YB Batched Nested Loop Join (actual time=4.617..263.848 rows=489406 loops=1)
                                       Join Filter: (s.s_suppkey = l.lo_suppkey)
                                       ->  Index Scan using supplier_pkey on supplier s (actual time=1.721..1.756 rows=163 loops=1)
                                             Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                       ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.736..120.930 rows=489406 loops=1)
                                             Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1999]))
                                             Heap Fetches: 0
                                 ->  Hash (actual time=17.276..17.277 rows=12068 loops=1)
                                       Buckets: 16384  Batches: 1  Memory Usage: 553kB
                                       ->  Index Only Scan using q3_1_c on customer c (actual time=2.009..15.815 rows=12068 loops=1)
                                             Index Cond: (c_region = 'AMERICA'::text)
                                             Heap Fetches: 0
                     ->  Index Scan using part_pkey on part p (actual time=2.475..34.728 rows=80046 loops=1)
                           Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=4.649..4.649 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.556..4.344 rows=2556 loops=1)
 Planning Time: 2.554 ms
 Execution Time: 485.208 ms
 Peak Memory Usage: 19204 kB
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