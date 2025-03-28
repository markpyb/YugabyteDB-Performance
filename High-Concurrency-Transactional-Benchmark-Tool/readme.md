A concurrent Go-based load generator featuring a simple real-time display for YugabyteDB performance. Includes an easily customizable workload, currently demonstrating microbatch transactional writes and primary key lookups at scale, with configurable connection pooling and live statistics monitoring.


```
wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

go mod init yugabyte_go_app
go get github.com/fatih/color
go get github.com/olekukonko/tablewriter
go get github.com/yugabyte/pgx/v5
 go get github.com/yugabyte/pgx/v5/pgxpool@v5.5.3-yb-5
```

```
ysqlsh -h eu-west-1.fb875775-afda-4745-9741-d42cb9abf9c3.aws.yugabyte.cloud -U admin -d nwbox -c "drop table payments;"
go run main.go -concurrency=48 -poolsize=250
```


<b>Server-side pooling through YugabyteDB connection manager required.</b>

```
ysqlsh -h eu-west-1.fb875775-afda-4745-9741-d42cb9abf9c3.aws.yugabyte.cloud -U admin -d nwbox -c "drop table payments;"
go run main.go -concurrency=114 -poolsize=1000
```

```
ysqlsh -h eu-west-1.fb875775-afda-4745-9741-d42cb9abf9c3.aws.yugabyte.cloud -U admin -d nwbox  -c "drop table payments;"
go run main.go -concurrency=252 -poolsize=2500
```