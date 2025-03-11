DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS part CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS date_tbl CASCADE;
DROP TABLE IF EXISTS lineorder CASCADE;

CREATE TABLE customer(
c_custkey INTEGER NOT NULL,
c_name VARCHAR(25) NOT NULL,
c_address VARCHAR(25) NOT NULL,
c_city VARCHAR(10) NOT NULL,
c_nation VARCHAR(15) NOT NULL,
c_region VARCHAR(12) NOT NULL,
c_phone VARCHAR(15) NOT NULL,
c_mktsegment VARCHAR(10) NOT NULL,
PRIMARY KEY(c_custkey ASC)
);

CREATE TABLE part(
p_partkey INTEGER NOT NULL,
p_name VARCHAR(22) NOT NULL,
p_mfgr VARCHAR(6) NOT NULL,
p_category VARCHAR(7) NOT NULL,
p_brand1 VARCHAR(9) NOT NULL,
p_color VARCHAR(11) NOT NULL,
p_type VARCHAR(25) NOT NULL,
p_size INTEGER NOT NULL,
p_container VARCHAR(10) NOT NULL,
PRIMARY KEY(p_partkey ASC)
);

CREATE TABLE supplier(
s_suppkey INTEGER NOT NULL,
s_name VARCHAR(25) NOT NULL,
s_address VARCHAR(25) NOT NULL,
s_city VARCHAR(10) NOT NULL,
s_nation VARCHAR(15) NOT NULL,
s_region VARCHAR(12) NOT NULL,
s_phone VARCHAR(15) NOT NULL,
PRIMARY KEY(s_suppkey ASC)
);

CREATE TABLE date_tbl(
d_datekey DATE NOT NULL,
d_date VARCHAR(18) NOT NULL,
d_dayofweek VARCHAR(9) NOT NULL,
d_month VARCHAR(9) NOT NULL,
d_year INTEGER NOT NULL,
d_yearmonthnum INTEGER NOT NULL,
d_yearmonth VARCHAR(7) NOT NULL,
d_daynuminweek INTEGER NOT NULL,
d_daynuminmonth INTEGER NOT NULL,
d_daynuminyear INTEGER NOT NULL,
d_monthnuminyear INTEGER NOT NULL,
d_weeknuminyear INTEGER NOT NULL,
d_sellingseason VARCHAR(12) NOT NULL,
d_lastdayinweekfl VARCHAR(1) NOT NULL,
d_lastdayinmonthfl VARCHAR(1) NOT NULL,
d_holidayfl VARCHAR(1) NOT NULL,
d_weekdayfl VARCHAR(1) NOT NULL,
PRIMARY KEY(d_datekey ASC)
);

CREATE TABLE lineorder(
lo_orderkey INTEGER NOT NULL,
lo_linenumber INTEGER NOT NULL,
lo_custkey INTEGER NOT NULL,
lo_partkey INTEGER NOT NULL,
lo_suppkey INTEGER NOT NULL,
lo_orderdate DATE NOT NULL,
lo_orderpriority VARCHAR(15) NOT NULL,
lo_shippriority INTEGER NOT NULL,
lo_quantity INTEGER NOT NULL,
lo_extendedprice INTEGER NOT NULL,
lo_ordertotalprice INTEGER NOT NULL,
lo_discount INTEGER NOT NULL,
lo_revenue INTEGER NOT NULL,
lo_supplycost INTEGER NOT NULL,
lo_tax INTEGER NOT NULL,
lo_commitdate DATE NOT NULL,
lo_shipmode VARCHAR(10) NOT NULL,
PRIMARY KEY(lo_orderkey ASC, lo_linenumber)
);

create index q1_1 on lineorder(lo_orderdate ASC, lo_discount, lo_quantity) include(lo_extendedprice);
create index q1_1_2 on lineorder(lo_discount ASC , lo_quantity, lo_orderdate ASC) include(lo_extendedprice);
create index q2_1_d on date_tbl(d_datekey ASC, d_year ASC);
create index q2_1_l on lineorder(lo_partkey ASC, lo_suppkey, lo_orderdate ASC) include(lo_revenue);
create index q2_1_p on part( p_category ASC, p_partkey ASC,  p_brand1 ASC); 
create index q2_1_s on supplier(s_region ASC, s_suppkey ASC);
create index q2_2_p on part(p_brand1 ASC, p_partkey);

create index q3_1_2 on lineorder( lo_custkey ASC, lo_orderdate ASC,  lo_suppkey ASC , lo_revenue DESC ); 
create index q3_1_s on supplier(s_region ASC, s_suppkey, s_nation);
create index q3_1_d on date_tbl(d_year, d_datekey);
create index q3_1_c on customer(c_region ASC, c_custkey, c_nation);

create index q4_1_p on part(p_mfgr ASC, p_partkey);
create index q4_1_l on lineorder(lo_partkey ASC, lo_orderdate ASC, lo_suppkey, lo_custkey) include(lo_revenue, lo_supplycost);
create index q4_1_2l on lineorder(lo_suppkey,  lo_orderdate ASC, lo_partkey ASC,  lo_custkey) include(lo_revenue, lo_supplycost);

\COPY customer FROM 'customer.tbl' WITH (FORMAT csv, DELIMITER ',', QUOTE '"');
\COPY part FROM 'part.tbl' WITH (FORMAT csv, DELIMITER ',', QUOTE '"');
\COPY supplier FROM 'supplier.tbl' WITH (FORMAT csv, DELIMITER ',', QUOTE '"');
\COPY date_tbl FROM 'date.tbl' WITH (FORMAT csv, DELIMITER ',', QUOTE '"');
\COPY lineorder FROM 'lineorder.tbl' WITH (FORMAT csv, DELIMITER ',', QUOTE '"');

alter database yugabyte set yb_enable_base_scans_cost_model=true; 
alter database yugabyte set work_mem='32MB';
\c yugabyte
analyze;

