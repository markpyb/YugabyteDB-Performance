DROP TABLE IF EXISTS staging.customer;

CREATE TABLE staging.customer (
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
);

INSERT INTO staging.customer (
    id, customercode, clientname, panno, ourcode, schemecode, ucid, strategycode, createddate, updateddate, usequity_accountid, email, branch
)
SELECT
    gen_random_uuid(),
    generate_series,
    'Client_' || generate_series,
    'PAN' || lpad((generate_series % 9999999999)::text, 10, '0'),
    'OUR' || lpad((generate_series % 999999)::text, 6, '0'),
    (generate_series % 999999999999999999),
    generate_series % 99999999,
    (generate_series % 999999999999999999),
    NOW() - INTERVAL '1 day' * (generate_series % 365),
    NOW(),
    'ACCT' || generate_series,
    'email' || generate_series || '@example.com',
    'Branch_' || (generate_series % 1000)
FROM generate_series(1, 12194187);


CREATE OR REPLACE FUNCTION ctas(oldtablename TEXT, newtablename TEXT, primarykey TEXT)
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
    pk_exists INTEGER;
BEGIN
    SELECT COUNT(*) INTO pk_exists
    FROM information_schema.columns
    WHERE table_name = oldtablename
      AND column_name IN (SELECT TRIM(col) FROM unnest(string_to_array(primarykey, ',')) AS col);

    IF pk_exists = 0 THEN
        RAISE EXCEPTION 'Primary key column(s) % do not exist in table %', primarykey, oldtablename;
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