<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/banner.svg">
  <source media="(prefers-color-scheme: light)" srcset="assets/banner.svg">
  <img alt="mssql-mcp-go" src="assets/banner.svg" width="100%">
</picture>

<br/>

[![CI](https://github.com/vinaycharlie01/mssql-mcp-go/actions/workflows/ci.yml/badge.svg)](https://github.com/vinaycharlie01/mssql-mcp-go/actions/workflows/ci.yml)
[![Go Version](https://img.shields.io/badge/Go-1.25+-00ADD8?style=flat&logo=go)](https://golang.org)
[![MCP Protocol](https://img.shields.io/badge/MCP-Compatible-blue?style=flat)](https://modelcontextprotocol.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

A **read-only** [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server for Microsoft SQL Server, written in Go. It gives AI assistants safe, structured access to your SQL Server databases for schema exploration, data profiling, query analysis, migration planning and more.

## Features

- **Read-only by design** -- every query is validated before execution; INSERT, UPDATE, DELETE, DROP and other mutating statements are blocked.
- **70+ tools** covering schema discovery, data profiling, performance analysis, security auditing, migration assessment, and monitoring.
- **Always Encrypted support** -- client-side column decryption via local PFX certificates.
- **Connection pooling** with configurable limits and automatic cleanup.
- **Stdio transport** for seamless integration with Claude Desktop, Cline and other MCP clients.

## Installation

### Homebrew (macOS / Linux)

```bash
brew install vinaycharlie01/tap/mssql-mcp-go
```

### Download a binary

Pre-built binaries for Linux, macOS and Windows (amd64 / arm64) are published with every [GitHub release](https://github.com/vinaycharlie01/mssql-mcp-go/releases).

```bash
# Example: download the latest release for macOS arm64
curl -LO https://github.com/vinaycharlie01/mssql-mcp-go/releases/latest/download/mssql-mcp-go_darwin_arm64.tar.gz
tar xzf mssql-mcp-go_darwin_arm64.tar.gz
sudo mv mssql-mcp-go /usr/local/bin/
```

### Docker

```bash
docker pull ghcr.io/vinaycharlie01/mssql-mcp-go:latest

docker run --rm \
  -e SQLSERVER_HOST=host.docker.internal \
  -e SQLSERVER_PORT=1433 \
  -e SQLSERVER_USER=readonly_user \
  -e SQLSERVER_PASSWORD=secret \
  -e SQLSERVER_DATABASE=MyDatabase \
  ghcr.io/vinaycharlie01/mssql-mcp-go:latest
```

### Build from source

Requires Go 1.25+ and [Task](https://taskfile.dev).

```bash
git clone https://github.com/vinaycharlie01/mssql-mcp-go.git
cd mssql-mcp-go
go install github.com/go-task/task/v3/cmd/task@latest
task build
# binary is at dist/mssql-mcp-go
```

## Quick start

### 1. Configure the database connection

The server reads settings from a `config.yaml` file or from environment variables. Environment variables always override the file.

```bash
cp config.yaml.example config.yaml
# edit config.yaml with your database credentials
```

Or export environment variables:

```bash
export SQLSERVER_HOST=localhost
export SQLSERVER_PORT=1433
export SQLSERVER_USER=readonly_user
export SQLSERVER_PASSWORD=secret
export SQLSERVER_DATABASE=MyDatabase
```

### 2. Run the server

```bash
mssql-mcp-go
```

The server starts on stdio by default and waits for an MCP client to connect.

## Configuration

Create a `config.yaml` (see `config.yaml.example` for all options):

```yaml
database:
  host: "localhost"
  port: 1433
  user: "readonly_user"
  password: ""              # prefer SQLSERVER_PASSWORD env var
  database: "MyDatabase"
  encrypt: "true"           # true, false or disable
  trust_server_certificate: false
  connection_timeout: 30

# Always Encrypted (client-side column decryption).
encryption:
  enabled: false
  key_path: ""              # absolute path to the .pfx file
  key_password: ""          # prefer SQLSERVER_ALWAYS_ENCRYPTED_KEY_PASSWORD env var

query:
  max_length: 5000          # max characters per query
  max_rows: 1000            # max rows returned
  timeout: 30s              # per-query timeout

pool:
  max_open_conns: 10
  max_idle_conns: 5
  conn_max_lifetime: 1h

logging:
  level: "info"             # debug, info, warn, error
  format: "json"            # json, text

mcp:
  transport: "stdio"        # stdio or http
  port: 9090
```

### Environment variables

| Variable | Description |
|---|---|
| `SQLSERVER_HOST` | Database host |
| `SQLSERVER_PORT` | Database port (default 1433) |
| `SQLSERVER_USER` | Database user |
| `SQLSERVER_PASSWORD` | Database password |
| `SQLSERVER_DATABASE` | Database name |
| `SQLSERVER_ENCRYPT` | Encryption mode (default `true`) |
| `SQLSERVER_TRUST_SERVER_CERTIFICATE` | Trust self-signed certs |
| `SQLSERVER_CONNECTION_TIMEOUT` | Connection timeout in seconds |
| `SQLSERVER_ALWAYS_ENCRYPTED_KEY_PATH` | Path to PFX certificate |
| `SQLSERVER_ALWAYS_ENCRYPTED_KEY_PASSWORD` | PFX certificate password |
| `QUERY_MAX_LENGTH` | Max query length |
| `QUERY_MAX_ROWS` | Max result rows |
| `QUERY_TIMEOUT_SECONDS` | Per-query timeout |
| `LOG_LEVEL` | Log level |
| `LOG_FORMAT` | Log format |
| `CONFIG_PATH` | Path to config.yaml |

## MCP client integration

### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mssql": {
      "command": "mssql-mcp-go",
      "env": {
        "SQLSERVER_HOST": "localhost",
        "SQLSERVER_PORT": "1433",
        "SQLSERVER_USER": "readonly_user",
        "SQLSERVER_PASSWORD": "secret",
        "SQLSERVER_DATABASE": "MyDatabase",
        "SQLSERVER_ENCRYPT": "disable"
      }
    }
  }
}
```

If you installed via Homebrew, the `mssql-mcp-go` binary is already on your PATH. Otherwise use the full path to the binary.

### Claude Desktop with Docker

```json
{
  "mcpServers": {
    "mssql": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-e", "SQLSERVER_HOST=host.docker.internal",
        "-e", "SQLSERVER_PORT=1433",
        "-e", "SQLSERVER_USER=readonly_user",
        "-e", "SQLSERVER_PASSWORD=secret",
        "-e", "SQLSERVER_DATABASE=MyDatabase",
        "ghcr.io/vinaycharlie01/mssql-mcp-go:latest"
      ]
    }
  }
}
```

### Cline (VS Code)

Add to your Cline MCP settings:

```json
{
  "mssql": {
    "command": "mssql-mcp-go",
    "env": {
      "SQLSERVER_HOST": "localhost",
      "SQLSERVER_PORT": "1433",
      "SQLSERVER_USER": "readonly_user",
      "SQLSERVER_PASSWORD": "secret",
      "SQLSERVER_DATABASE": "MyDatabase"
    }
  }
}
```

## Available tools

### Core query

| Tool | Description |
|---|---|
| `execute_query` | Run a read-only SELECT/WITH query |
| `health_check` | Check database connectivity and pool stats |

### Database discovery

| Tool | Description |
|---|---|
| `list_databases` | List accessible databases |
| `list_schemas` | List schemas in the current database |
| `list_tables` | List tables with row/column counts |
| `describe_table` | Columns, keys, indexes of a table |
| `list_columns` | Columns with types and nullability |
| `describe_column` | Detailed metadata for a single column |
| `table_row_count` | Row count from catalog metadata |

### Relationships and keys

| Tool | Description |
|---|---|
| `table_relationships` | Outbound and inbound foreign keys |
| `list_foreign_keys` | FK constraints, optionally by schema |
| `list_primary_keys` | PK constraints, optionally by schema |
| `foreign_key_graph` | Full FK graph as nodes and edges |
| `list_unique_constraints` | Unique constraints by schema |
| `list_check_constraints` | CHECK constraints by schema |
| `list_default_constraints` | DEFAULT constraints by schema |

### Stored procedures

| Tool | Description |
|---|---|
| `list_procedures` | List stored procedures |
| `get_procedure_definition` | Full T-SQL definition and parameters |
| `search_procedures` | Search definitions by keyword |
| `analyze_stored_procedure` | Static analysis: tables, views, transactions, etc. |
| `extract_tables_used` | Tables referenced by a procedure |
| `extract_views_used` | Views referenced by a procedure |
| `extract_functions_used` | Functions referenced by a procedure |
| `extract_called_procedures` | Procedures called via EXEC |
| `extract_transaction_usage` | Transaction control usage |
| `extract_dynamic_sql` | Dynamic SQL detection |
| `extract_cursor_usage` | Cursor declarations |
| `extract_temp_tables` | Temp table usage |
| `extract_error_handling` | Error handling constructs |
| `extract_validation_rules` | Validation rules |
| `extract_business_rules` | Business-rule comments |

### Views

| Tool | Description |
|---|---|
| `list_views` | List all views |
| `get_view_definition` | SQL definition of a view |
| `analyze_view` | Columns and referenced objects |
| `trace_view_sources` | Resolve underlying base tables |
| `extract_view_dependencies` | Objects a view depends on |

### Functions

| Tool | Description |
|---|---|
| `list_functions` | Scalar, inline and table-valued functions |
| `get_function_definition` | T-SQL definition and parameters |
| `analyze_function` | Static analysis |
| `trace_function_usage` | Objects referencing the function |
| `extract_function_dependencies` | Objects a function depends on |

### Triggers

| Tool | Description |
|---|---|
| `list_triggers` | DML triggers with their tables |
| `get_trigger_definition` | T-SQL definition |
| `analyze_trigger` | Static analysis |

### Object dependencies and search

| Tool | Description |
|---|---|
| `find_object_dependencies` | Objects an object depends on |
| `find_object_references` | Objects that reference an object |
| `find_table_usage` | All objects referencing a table |
| `search_objects_by_keyword` | Search names and definitions |
| `generate_erd` | Entity-relationship description |
| `dependency_graph` | Recursive dependency graph |
| `find_column_usage` | Modules referencing a column |
| `find_unused_tables` | Tables with no references |
| `find_unused_columns` | Columns with no tracked references |
| `find_orphan_tables` | Tables with no FK connections |
| `find_circular_dependencies` | FK graph cycles |

### Search

| Tool | Description |
|---|---|
| `search_tables` | Tables matching a keyword |
| `search_columns` | Columns matching a keyword |
| `search_views` | Views matching a keyword |
| `search_functions` | Functions matching a keyword |

### Data profiling

| Tool | Description |
|---|---|
| `table_statistics` | Row count, column count, storage stats |
| `column_statistics` | Min/max/distinct/null statistics |
| `column_distinct_values` | Top distinct values with frequencies |
| `column_null_analysis` | Null count and percentage |
| `data_distribution` | Value-frequency distribution |
| `sample_table_data` | Sample rows from a table |
| `find_duplicate_rows` | Duplicate groups by columns |
| `find_candidate_keys` | Single-column candidate key detection |

### Performance analysis

| Tool | Description |
|---|---|
| `explain_query` | Estimated execution plan |
| `estimate_query_cost` | Estimated subtree cost |
| `analyze_execution_plan` | Plan with operator summary |
| `find_missing_indexes` | Optimizer-recommended indexes |
| `find_unused_indexes` | Indexes never read |
| `find_fragmented_indexes` | High-fragmentation indexes |
| `index_usage_report` | Read/write stats for all indexes |
| `slow_query_analysis` | Most expensive cached queries |
| `query_performance_report` | Aggregate query stats |

### Security analysis

| Tool | Description |
|---|---|
| `list_logins` | Server-level logins |
| `list_users` | Database-level users |
| `list_roles` | Database roles |
| `list_permissions` | Database permission grants |
| `user_permissions` | Permissions for a specific user |
| `role_memberships` | Role-membership graph |
| `object_permissions` | Permissions on a specific object |

### Migration assessment

| Tool | Description |
|---|---|
| `database_overview` | High-level object counts |
| `database_health_report` | Health indicators |
| `database_complexity_report` | Structural complexity metrics |
| `analyze_database_for_migration` | Comprehensive migration assessment |
| `migration_complexity_score` | Weighted complexity score |
| `migration_priority_order` | Dependency-based migration order |
| `high_risk_objects` | Modules with risky constructs |
| `large_table_analysis` | Largest tables by storage |
| `legacy_object_analysis` | Stale/legacy objects |
| `deprecated_feature_detection` | Deprecated feature scan |

### Monitoring

| Tool | Description |
|---|---|
| `connection_pool_stats` | Connection pool statistics |
| `database_size_report` | Data/log file sizes |
| `table_growth_report` | Largest tables by size |

## Architecture

```
mssql-mcp-go/
  cmd/server/            Entry point
  internal/
    adapters/mcp/        MCP protocol, tool registration
    mssql/               Service layer (queries, analysis)
    db/                  Connection pool, query execution, encryption
    infrastructure/      Config, logging
  pkg/version/           Build version info
```

The server starts via stdio, registers all tools with the MCP SDK, and forwards tool calls to the SQL Server service layer. Every query goes through a read-only validator that blocks mutating SQL before it reaches the database.

## Security

- All queries are validated -- INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE and other mutating operations are rejected before execution.
- Stored procedures and functions are analyzed statically, never executed.
- Always Encrypted columns are decrypted client-side using local PFX certificates.
- Connection pooling with configurable limits prevents resource exhaustion.
- TLS encryption is supported for database connections (`encrypt: true` by default).

## Development

```bash
task build          # compile the binary
task test           # run unit tests
task race           # run tests with race detector
task coverage       # generate coverage report
task bench          # run benchmarks
task lint           # run golangci-lint
task release        # build release with goreleaser
```

## License

MIT -- see [LICENSE](LICENSE).
