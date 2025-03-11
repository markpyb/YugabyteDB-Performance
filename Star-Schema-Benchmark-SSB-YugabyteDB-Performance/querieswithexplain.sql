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
