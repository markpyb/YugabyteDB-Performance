package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math"
	"math/rand"
	"net"
	"os"
	"strconv"
	"sync"
	"sync/atomic"
	"time"

	"github.com/fatih/color"
	"github.com/olekukonko/tablewriter"
	"github.com/yugabyte/pgx/v5"
	"github.com/yugabyte/pgx/v5/pgxpool"
)

type Stats struct {
	InsertsCount  int64
	SelectsCount  int64
	TotalDuration int64
	StartTime     time.Time
	mu            sync.Mutex
}

func main() {
	rand.Seed(time.Now().UnixNano())
	concurrency := flag.Int("concurrency", 100, "")
	poolSize := flag.Int("poolsize", 100, "")
	flag.Parse()

	dsn := "postgresql://user:pw@host:5433/db?sslmode=require&load_balance=false"
	pool, err := connectToDBWithRetry(dsn, 5, 5*time.Second, *poolSize)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer pool.Close()
	forceOpenPool(pool, *poolSize)

	createTable(pool)

	stats := &Stats{StartTime: time.Now()}
	for i := 0; i < *concurrency; i++ {
		go worker(pool, stats)
	}

	go logStats(stats, pool)
	select {}
}

func connectToDBWithRetry(dsn string, maxRetries int, retryInterval time.Duration, size int) (*pgxpool.Pool, error) {
	var pool *pgxpool.Pool
	var err error
	for i := 0; i < maxRetries; i++ {
		pool, err = connectToDB(dsn, size)
		if err == nil {
			return pool, nil
		}
		time.Sleep(retryInterval)
	}
	return nil, fmt.Errorf("failed after %d attempts: %w", maxRetries, err)
}

func connectToDB(dsn string, size int) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, err
	}
	config.ConnConfig.DialFunc = (&net.Dialer{Timeout: 15 * time.Second}).DialContext
	config.MinConns = int32(size)
	config.MaxConns = int32(size)
	config.MaxConnLifetime = 3 * time.Hour
	config.BeforeAcquire = func(ctx context.Context, conn *pgx.Conn) bool {
		return conn.Ping(ctx) == nil
	}
	return pgxpool.NewWithConfig(context.Background(), config)
}

func forceOpenPool(pool *pgxpool.Pool, size int) {
	ctx := context.Background()
	var conns []*pgxpool.Conn
	for i := 0; i < size; i++ {
		conn, err := pool.Acquire(ctx)
		if err != nil {
			break
		}
		conns = append(conns, conn)
	}
	for _, c := range conns {
		c.Release()
	}
}

func createTable(pool *pgxpool.Pool) {
	sql := `
	CREATE TABLE IF NOT EXISTS payments (
		payment_id BIGSERIAL,
		account_id integer,
		amount numeric(19,2),
		currency varchar(10),
		payment_date timestamp,
		status varchar(20), primary key(payment_id hash)
	)split into 3 tablets`
	_, err := pool.Exec(context.Background(), sql)
	if err != nil {
		log.Fatalf("Failed to create table: %v", err)
	}
}

func worker(pool *pgxpool.Pool, stats *Stats) {
	ctx := context.Background()
	for {
		start := time.Now()

		tx, err := pool.Begin(ctx)
		if err != nil {
			log.Printf("Failed to begin transaction: %v", err)
			continue
		}

		// 40 inserts in a transaction
		for i := 0; i < 40; i++ {
			_, err := tx.Exec(ctx, `INSERT INTO payments (account_id, amount, currency, payment_date, status) VALUES ($1, $2, $3, $4, $5)`,
				rand.Intn(1000000),
				math.Round(rand.Float64()*100000*100)/100,
				"GBP",
				time.Now().Add(-time.Duration(rand.Intn(365*24))*time.Hour),
				"completed")
			if err != nil {
				log.Printf("Insert failed: %v", err)
				tx.Rollback(ctx)
				break
			}
		}
		err = tx.Commit(ctx)
		if err != nil {
			log.Printf("Commit failed: %v", err)
			continue
		}

		atomic.AddInt64(&stats.InsertsCount, 40)

		// 200 selects without transactions
		for i := 0; i < 200; i++ {
			var dummy int
			id := rand.Intn(100000000)
			_ = pool.QueryRow(ctx, "SELECT payment_id FROM payments WHERE payment_id = $1", id).Scan(&dummy)
		}
		atomic.AddInt64(&stats.SelectsCount, 200)

		atomic.AddInt64(&stats.TotalDuration, int64(time.Since(start)))
	}
}

func logStats(stats *Stats, pool *pgxpool.Pool) {
	ticker := time.NewTicker(1 * time.Second)
	for range ticker.C {
		displayStats(stats, pool)
	}
}

func displayStats(stats *Stats, pool *pgxpool.Pool) {
	fmt.Print("\033[2J\033[H")

	color.New(color.FgHiBlue).Println("╔══════════════════════════════════════╗")
	color.New(color.FgHiBlue).Println("║          Load Harness                ║")
	color.New(color.FgHiBlue).Println("╚══════════════════════════════════════╝")

	color.New(color.FgWhite).Printf("\nTimestamp: %s\n", time.Now().Format("2006-01-02 15:04:05"))

	insertsCount := atomic.SwapInt64(&stats.InsertsCount, 0)
	selectsCount := atomic.SwapInt64(&stats.SelectsCount, 0)
	opsCount := insertsCount + selectsCount

	poolStats := pool.Stat()

	table := tablewriter.NewWriter(os.Stdout)
	table.SetHeader([]string{"Ops/sec", "Inserts/sec", "Selects/sec", "Active Connections", "Idle Connections"})
	table.Append([]string{
		strconv.FormatInt(opsCount, 10),
		strconv.FormatInt(insertsCount, 10),
		strconv.FormatInt(selectsCount, 10),
		fmt.Sprintf("%d", poolStats.AcquiredConns()),
		fmt.Sprintf("%d", poolStats.IdleConns()),
	})
	table.Render()
}
