select 'Q3.1' as query;
/*+ IndexOnlyScan(c q3_1_c) IndexOnlyScan(l q3_1_2) */
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
