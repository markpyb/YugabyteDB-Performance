# Running SSB (Star Schema Benchmark) on YugabyteDB

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
Preparing the files
-----

```
rm -f *.tbl
./dbgen -s 1 -T c
./dbgen -s 1 -T p
./dbgen -s 1 -T s
./dbgen -s 1 -T d
./dbgen -s 1 -T l
sed -i 's/,$//' *.tbl
export PGPASSWORD="pw!"
```

---
Preparing the schema and loading the data

```
ysqlsh -h {host} -c "\i schema_and_data.sql"
```

---
Executing example Q1 to Q4 SSB benchmark queries 

```
ysqlsh -h {host} -c "\i querieswithexplain.sql" > querieswithexplain_results.txt
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
Listing the results from said queries
---

```
 query 
-------
 Q1.1
(1 row)

                                                                           QUERY PLAN                                                                           
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=97.799..97.799 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=4.117..89.966 rows=118598 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Only Scan using q3_1_d on date_tbl d (actual time=0.422..0.479 rows=365 loops=1)
               Index Cond: (d_year = 1993)
               Heap Fetches: 0
         ->  Index Only Scan using q1_1 on lineorder l (actual time=3.516..56.854 rows=118598 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 1) AND (lo_discount <= 3) AND (lo_quantity < 25))
               Heap Fetches: 0
 Planning Time: 190.367 ms
 Execution Time: 102.277 ms
 Peak Memory Usage: 690 kB
(12 rows)

 query 
-------
 Q1.2
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=7.566..7.566 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=3.652..7.285 rows=4301 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.276..2.282 rows=31 loops=1)
               Storage Filter: (d_yearmonthnum = 199401)
         ->  Index Only Scan using q1_1 on lineorder l (actual time=1.315..3.807 rows=4301 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 4) AND (lo_discount <= 6) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.612 ms
 Execution Time: 7.742 ms
 Peak Memory Usage: 476 kB
(11 rows)

 query 
-------
 Q1.3
(1 row)

                                                                                       QUERY PLAN                                                                                        
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=3.779..3.780 rows=1 loops=1)
   ->  YB Batched Nested Loop Join (actual time=3.285..3.704 rows=955 loops=1)
         Join Filter: (l.lo_orderdate = d.d_datekey)
         ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.530..2.533 rows=7 loops=1)
               Storage Filter: ((d_weeknuminyear = 6) AND (d_year = 1994))
         ->  Index Only Scan using q1_1 on lineorder l (actual time=0.700..0.874 rows=955 loops=1)
               Index Cond: ((lo_orderdate = ANY (ARRAY[d.d_datekey, $1, $2, ..., $1023])) AND (lo_discount >= 5) AND (lo_discount <= 7) AND (lo_quantity >= 26) AND (lo_quantity <= 35))
               Heap Fetches: 0
 Planning Time: 0.605 ms
 Execution Time: 3.912 ms
 Peak Memory Usage: 476 kB
(11 rows)

 query 
-------
 Q2.1
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=622.722..629.696 rows=280 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=622.688..625.301 rows=44532 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 5016kB
         ->  Hash Join (actual time=16.050..604.630 rows=44532 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=9.774..589.066 rows=44532 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=8.616..564.265 rows=236840 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_1_p on part p (actual time=3.126..5.917 rows=7883 loops=1)
                                 Index Cond: (p_category = 'MFGR#12'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=2.792..60.549 rows=29605 loops=8)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=1.130..1.130 rows=378 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=0.995..1.080 rows=378 loops=1)
                                 Index Cond: (s_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=6.249..6.249 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.078..5.964 rows=2556 loops=1)
 Planning Time: 96.509 ms
 Execution Time: 630.122 ms
 Peak Memory Usage: 7471 kB
(28 rows)

 query 
-------
 Q2.2
(1 row)

                                                        QUERY PLAN                                                        
--------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=126.059..127.392 rows=56 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=126.027..126.425 rows=10513 loops=1)
         Sort Key: d.d_year, p.p_brand1
         Sort Method: quicksort  Memory: 1206kB
         ->  Hash Join (actual time=14.555..123.288 rows=10513 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=6.963..113.709 rows=10513 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=5.544..107.357 rows=47572 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=2.870..3.260 rows=1584 loops=1)
                                 Index Cond: ((p_brand1 >= 'MFGR#2221'::text) AND (p_brand1 <= 'MFGR#2228'::text))
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=1.812..44.671 rows=23786 loops=2)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=1.388..1.388 rows=449 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 24kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=1.231..1.331 rows=449 loops=1)
                                 Index Cond: (s_region = 'ASIA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=7.580..7.580 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.692..7.261 rows=2556 loops=1)
 Planning Time: 5.734 ms
 Execution Time: 127.622 ms
 Peak Memory Usage: 2946 kB
(28 rows)

 query 
-------
 Q2.3
(1 row)

                                                       QUERY PLAN                                                       
------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=21.987..22.156 rows=7 loops=1)
   Group Key: d.d_year, p.p_brand1
   ->  Sort (actual time=21.948..22.011 rows=1277 loops=1)
         Sort Key: d.d_year
         Sort Method: quicksort  Memory: 148kB
         ->  Hash Join (actual time=10.171..21.744 rows=1277 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=3.953..15.282 rows=1277 loops=1)
                     Hash Cond: (l.lo_suppkey = s.s_suppkey)
                     ->  YB Batched Nested Loop Join (actual time=3.210..13.904 rows=6569 loops=1)
                           Join Filter: (l.lo_partkey = p.p_partkey)
                           ->  Index Only Scan using q2_2_p on part p (actual time=1.938..2.003 rows=216 loops=1)
                                 Index Cond: (p_brand1 = 'MFGR#2239'::text)
                                 Heap Fetches: 0
                           ->  Index Only Scan using q2_1_l on lineorder l (actual time=1.105..9.868 rows=6569 loops=1)
                                 Index Cond: (lo_partkey = ANY (ARRAY[p.p_partkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=0.731..0.731 rows=380 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 22kB
                           ->  Index Only Scan using q3_1_s on supplier s (actual time=0.601..0.685 rows=380 loops=1)
                                 Index Cond: (s_region = 'EUROPE'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=6.209..6.209 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.403..5.917 rows=2556 loops=1)
 Planning Time: 1.285 ms
 Execution Time: 22.366 ms
 Peak Memory Usage: 1266 kB
(28 rows)

 query 
-------
 Q3.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1498.640..1498.646 rows=150 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 36kB
   ->  GroupAggregate (actual time=1458.230..1497.145 rows=150 loops=1)
         Group Key: c.c_nation, s.s_nation, d.d_year
         ->  Sort (actual time=1457.948..1470.022 rows=247638 loops=1)
               Sort Key: c.c_nation, s.s_nation, d.d_year
               Sort Method: quicksort  Memory: 25491kB
               ->  Hash Join (actual time=14.917..1337.425 rows=247638 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=8.758..1286.775 rows=271598 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=4.615..1108.830 rows=1347435 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=0.674..0.802 rows=449 loops=1)
                                       Index Cond: (s_region = 'ASIA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=3.647..708.467 rows=1347435 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=4.112..4.113 rows=6051 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 329kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=0.970..3.368 rows=6051 loops=1)
                                       Index Cond: (c_region = 'ASIA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=6.150..6.150 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.261..5.895 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 38.408 ms
 Execution Time: 1499.061 ms
 Peak Memory Usage: 33635 kB
(32 rows)

 query 
-------
 Q3.2
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=193.137..193.157 rows=599 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 71kB
   ->  GroupAggregate (actual time=191.592..192.859 rows=599 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=191.579..191.887 rows=8541 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 1052kB
               ->  Hash Join (actual time=20.072..187.094 rows=8541 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=14.351..179.886 rows=9417 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=3.028..149.269 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=0.994..1.010 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=1.959..82.274 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=11.280..11.280 rows=1260 loops=1)
                                 Buckets: 2048  Batches: 1  Memory Usage: 76kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=8.727..11.121 rows=1260 loops=1)
                                       Storage Filter: ((c_nation)::text = 'UNITED STATES'::text)
                     ->  Hash (actual time=5.709..5.709 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=1.760..5.482 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.336 ms
 Execution Time: 193.431 ms
 Peak Memory Usage: 2658 kB
(30 rows)

 query 
-------
 Q3.3
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=1434.281..1434.851 rows=14983 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 1555kB
   ->  GroupAggregate (actual time=1372.054..1424.992 rows=14983 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=1372.038..1393.240 rows=221706 loops=1)
               Sort Key: c.c_city, s.s_city, d.d_year
               Sort Method: quicksort  Memory: 23465kB
               ->  Hash Join (actual time=25.975..1214.946 rows=221706 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  Hash Join (actual time=20.126..1169.463 rows=243624 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=4.878..998.734 rows=1216916 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.454..1.537 rows=405 loops=1)
                                       Storage Filter: ("substring"((s_phone)::text, 1, 1) = '3'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=3.210..637.656 rows=1216916 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=15.233..15.233 rows=5958 loops=1)
                                 Buckets: 8192 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 344kB
                                 ->  Index Scan using customer_pkey on customer c (actual time=2.540..14.518 rows=5958 loops=1)
                                       Storage Filter: ("substring"((c_phone)::text, 1, 1) = '3'::text)
                     ->  Hash (actual time=5.841..5.841 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.212..5.571 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.226 ms
 Execution Time: 1435.915 ms
 Peak Memory Usage: 35692 kB
(30 rows)

 query 
-------
 Q3.4
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 Sort (actual time=59.227..59.228 rows=6 loops=1)
   Sort Key: d.d_year, (sum(l.lo_revenue)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  GroupAggregate (actual time=59.206..59.218 rows=6 loops=1)
         Group Key: c.c_city, s.s_city, d.d_year
         ->  Sort (actual time=59.195..59.199 rows=89 loops=1)
               Sort Key: d.d_year
               Sort Method: quicksort  Memory: 31kB
               ->  Hash Join (actual time=22.553..59.159 rows=89 loops=1)
                     Hash Cond: (l.lo_orderdate = d.d_datekey)
                     ->  YB Batched Nested Loop Join (actual time=14.672..51.239 rows=98 loops=1)
                           Join Filter: ((c.c_custkey = l.lo_custkey) AND (s.s_suppkey = l.lo_suppkey))
                           Rows Removed by Join Filter: 53512
                           ->  Nested Loop (actual time=11.282..11.514 rows=1098 loops=1)
                                 ->  Index Scan using customer_pkey on customer c (actual time=10.055..10.091 rows=122 loops=1)
                                       Storage Filter: ((c_city)::text = 'UNITED KI1'::text)
                                 ->  Materialize (actual time=0.010..0.010 rows=9 loops=122)
                                       ->  Index Scan using supplier_pkey on supplier s (actual time=1.209..1.214 rows=9 loops=1)
                                             Storage Filter: ((s_city)::text = 'UNITED KI1'::text)
                           ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.566..16.963 rows=26805 loops=2)
                                 Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                 Heap Fetches: 0
                     ->  Hash (actual time=7.862..7.862 rows=2192 loops=1)
                           Buckets: 4096  Batches: 1  Memory Usage: 118kB
                           ->  Index Scan using date_tbl_pkey on date_tbl d (actual time=2.872..7.604 rows=2192 loops=1)
                                 Storage Filter: ((d_year >= 1992) AND (d_year <= 1997))
 Planning Time: 1.446 ms
 Execution Time: 59.431 ms
 Peak Memory Usage: 1263 kB
(29 rows)

 query 
-------
 Q4.1
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1131.362..1137.853 rows=35 loops=1)
   Group Key: d.d_year, c.c_nation
   ->  Sort (actual time=1131.117..1133.235 rows=45163 loops=1)
         Sort Key: d.d_year, c.c_nation
         Sort Method: quicksort  Memory: 5065kB
         ->  Hash Join (actual time=91.300..1119.903 rows=45163 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=85.290..1103.216 rows=45163 loops=1)
                     Hash Cond: (l.lo_custkey = c.c_custkey)
                     ->  Hash Join (actual time=81.240..1062.063 rows=226254 loops=1)
                           Hash Cond: (l.lo_partkey = p.p_partkey)
                           ->  YB Batched Nested Loop Join (actual time=4.094..799.358 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=0.529..0.621 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=3.337..486.134 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=77.068..77.069 rows=40103 loops=1)
                                 Buckets: 65536  Batches: 1  Memory Usage: 1922kB
                                 ->  Index Only Scan using q4_1_p on part p (actual time=1.612..70.808 rows=40103 loops=1)
                                       Index Cond: (p_mfgr = 'MFGR#1'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=4.020..4.020 rows=5992 loops=1)
                           Buckets: 8192  Batches: 1  Memory Usage: 336kB
                           ->  Index Only Scan using q3_1_c on customer c (actual time=0.800..3.286 rows=5992 loops=1)
                                 Index Cond: (c_region = 'AMERICA'::text)
                                 Heap Fetches: 0
               ->  Hash (actual time=6.001..6.002 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=2.188..5.710 rows=2556 loops=1)
 Planning Time: 2.881 ms
 Execution Time: 1138.188 ms
 Peak Memory Usage: 10759 kB
(35 rows)

 query 
-------
 Q4.2
(1 row)

                                                             QUERY PLAN                                                             
------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=1170.816..1185.278 rows=350 loops=1)
   Group Key: d.d_year, s.s_nation, p.p_category
   ->  Sort (actual time=1170.760..1174.683 rows=89953 loops=1)
         Sort Key: d.d_year, s.s_nation, p.p_category
         Sort Method: quicksort  Memory: 10100kB
         ->  Hash Join (actual time=118.738..1136.432 rows=89953 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=114.196..1113.680 rows=89953 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=6.791..936.141 rows=224890 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=3.481..793.062 rows=1133502 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Only Scan using q3_1_s on supplier s (actual time=0.397..0.510 rows=378 loops=1)
                                       Index Cond: (s_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.849..456.569 rows=1133502 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=3.283..3.283 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=0.688..2.663 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=107.318..107.318 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4464kB
                           ->  Index Scan using part_pkey on part p (actual time=1.197..94.673 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=4.531..4.531 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.366..4.278 rows=2556 loops=1)
 Planning Time: 2.395 ms
 Execution Time: 1185.650 ms
 Peak Memory Usage: 19722 kB
(34 rows)

 query 
-------
 Q4.3
(1 row)

                                                            QUERY PLAN                                                            
----------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate (actual time=345.400..349.078 rows=12797 loops=1)
   Group Key: d.d_year, s.s_city, p.p_brand1
   ->  Sort (actual time=345.391..346.063 rows=17994 loops=1)
         Sort Key: d.d_year, s.s_city, p.p_brand1
         Sort Method: quicksort  Memory: 2174kB
         ->  Hash Join (actual time=153.006..333.788 rows=17994 loops=1)
               Hash Cond: (l.lo_orderdate = d.d_datekey)
               ->  Hash Join (actual time=147.143..324.681 rows=17994 loops=1)
                     Hash Cond: (l.lo_partkey = p.p_partkey)
                     ->  Hash Join (actual time=9.405..172.431 rows=45355 loops=1)
                           Hash Cond: (l.lo_custkey = c.c_custkey)
                           ->  YB Batched Nested Loop Join (actual time=3.599..141.176 rows=228745 loops=1)
                                 Join Filter: (s.s_suppkey = l.lo_suppkey)
                                 ->  Index Scan using supplier_pkey on supplier s (actual time=1.136..1.153 rows=76 loops=1)
                                       Storage Filter: ((s_nation)::text = 'UNITED STATES'::text)
                                 ->  Index Only Scan using q4_1_2l on lineorder l (actual time=2.378..71.409 rows=228745 loops=1)
                                       Index Cond: (lo_suppkey = ANY (ARRAY[s.s_suppkey, $1, $2, ..., $1023]))
                                       Heap Fetches: 0
                           ->  Hash (actual time=5.783..5.783 rows=5992 loops=1)
                                 Buckets: 8192  Batches: 1  Memory Usage: 275kB
                                 ->  Index Only Scan using q3_1_c on customer c (actual time=0.878..5.157 rows=5992 loops=1)
                                       Index Cond: (c_region = 'AMERICA'::text)
                                       Heap Fetches: 0
                     ->  Hash (actual time=137.618..137.618 rows=80045 loops=1)
                           Buckets: 131072  Batches: 1  Memory Usage: 4777kB
                           ->  Index Scan using part_pkey on part p (actual time=1.864..122.435 rows=80045 loops=1)
                                 Storage Filter: (((p_mfgr)::text = 'MFGR#1'::text) OR ((p_mfgr)::text = 'MFGR#2'::text))
               ->  Hash (actual time=5.853..5.853 rows=2556 loops=1)
                     Buckets: 4096  Batches: 1  Memory Usage: 132kB
                     ->  Seq Scan on date_tbl d (actual time=1.934..5.564 rows=2556 loops=1)
 Planning Time: 2.301 ms
 Execution Time: 350.038 ms
 Peak Memory Usage: 10262 kB
(33 rows)
```
