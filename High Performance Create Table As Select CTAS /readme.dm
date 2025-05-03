YugabyteDB Specs:

M7i.4Xlarge RF3
Client to node TLS enabled
Node to node TLS disabled
Master flag -> ysql_num_shards_per_tserver=1

export PGPASSWORD="pw!"
ysqlsh -h 10.0.0.40

DROP TABLE IF EXISTS customer;

CREATE TABLE customer (
    id uuid PRIMARY KEY NOT NULL,
    customercode int8 NULL,
    clientname varchar(150) NULL,
    panno varchar(50) NULL,
    ourcode varchar(50) NULL,
    schemecode numeric(18) NULL,
    ucid int8 NULL,
    strategycode numeric(18) NULL,
    createddate timestamp NULL,
    updateddate timestamp NULL,
    usequity_accountid varchar(200) NULL,
    email varchar(150) NULL,
    branch varchar(100) NULL
) SPLIT INTO 3 TABLETS;


create extension pgcrypto;
\timing 

SET yb_disable_transactional_writes=true;
SET yb_enable_upsert_mode=true;
SET yb_fetch_row_limit=10000;

INSERT INTO staging.customer (
    id, customercode, clientname, panno, ourcode, schemecode, ucid, strategycode, createddate, updateddate, usequity_accountid, email, branch
)
SELECT
    gen_random_uuid(),
    generate_series,
    'C_' || generate_series,
    'PAN' || lpad((generate_series % 9999999)::text, 7, '0'),
    'OUR' || lpad((generate_series % 99999)::text, 5, '0'),
    (generate_series % 9999999999),
    generate_series % 9999999,
    (generate_series % 9999999999),
    CURRENT_DATE - (generate_series % 365),
    CURRENT_DATE,
    'ACCT' || (generate_series % 9999999),
    'e' || (generate_series % 9999999) || '@x.com',
    'B_' || (generate_series % 999)
FROM generate_series(1, 12194187);


reset yb_disable_transactional_writes;
reSET yb_enable_upsert_mode;
reSET yb_fetch_row_limit;

CREATE OR REPLACE FUNCTION ctas(oldtablename TEXT, newtablename TEXT)
RETURNS VOID AS $$
DECLARE
    total_rows BIGINT;
    chunk_count INTEGER;
    chunk_size INTEGER := 250000;
    max_hash INTEGER := 65536;
    hash_range INTEGER;
    start_hash INTEGER;
    end_hash INTEGER;
    i INTEGER := 0;
    percent_complete DECIMAL;
    sql TEXT;
    primarykey TEXT;
BEGIN
    SELECT string_agg(attname, ',') INTO primarykey
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
    WHERE i.indrelid = oldtablename::regclass AND i.indisprimary;

    IF primarykey IS NULL THEN
        RAISE EXCEPTION 'Primary key does not exist for table %', oldtablename;
    END IF;

    EXECUTE FORMAT('SELECT COUNT(*) * 128 FROM %I WHERE yb_hash_code((%s)) < 65536/128', oldtablename, primarykey)
    INTO total_rows;

    RAISE NOTICE 'Approximate row count: %', total_rows;

    chunk_count := CEIL(total_rows::DECIMAL / chunk_size);
    hash_range := CEIL(max_hash::DECIMAL / chunk_count);

    EXECUTE FORMAT('CREATE TABLE IF NOT EXISTS %I AS SELECT * FROM %I WHERE false', newtablename, oldtablename);

    EXECUTE 'SET yb_disable_transactional_writes=true';
    EXECUTE 'SET yb_enable_upsert_mode=true'; 
    EXECUTE 'RESET ysql_session_max_batch_size';
    EXECUTE 'SET yb_fetch_row_limit=10000';

    WHILE i < chunk_count LOOP
        start_hash := i * hash_range;
        end_hash := LEAST(((i + 1) * hash_range - 1), max_hash);

        sql := FORMAT(
            'INSERT INTO %I SELECT * FROM %I WHERE yb_hash_code((%s)) BETWEEN %s AND %s',
            newtablename,
            oldtablename,
            primarykey,
            start_hash,
            end_hash
        );

        percent_complete := ROUND((i::DECIMAL / chunk_count) * 100, 2);
        RAISE NOTICE 'Executing: %, approx % complete', sql, percent_complete || '%';

        EXECUTE sql;
        i := i + 1;
    END LOOP;

    EXECUTE 'RESET yb_disable_transactional_writes';
    EXECUTE 'RESET yb_enable_upsert_mode';
    EXECUTE 'RESET yb_fetch_row_limit';

    RAISE NOTICE 'CTAS operation completed: 100%%';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error occurred %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


SELECT ctas('customer', 'customer_backup');


