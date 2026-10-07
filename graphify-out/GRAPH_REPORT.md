# Graph Report - go_snowflake_ruby  (2026-10-07)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 164 nodes · 217 edges · 19 communities (10 shown, 9 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e87d9845`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Go C Bridge Layer
- Ruby Query Fetcher
- Go Connection Management
- Ruby Executor & Signals
- Ruby Integration Tests
- Ruby Database API
- Go Cursor & Fetching
- Project Documentation
- Ruby Base Executor
- Ruby Error Definitions
- Ruby Async Executor
- Go Async Execution
- Version Definition
- Docker Compose Config
- RuboCop Config

## God Nodes (most connected - your core abstractions)
1. `GoSnowflake::Fetcher` - 12 edges
2. `TestGoSnowflakeRubyDatabase` - 11 edges
3. `GoSnowflakeRuby::Database` - 10 edges
4. `GoSnowflake::Executor` - 9 edges
5. `GoSnowflake::SignalHandler` - 7 edges
6. `ConvertArgs()` - 7 edges
7. `Fetch()` - 7 edges
8. `openDbWithPrivateKey()` - 7 edges
9. `GoSnowflake::AsyncExecutor` - 6 edges
10. `GoSnowflake::BaseExecutor` - 6 edges

## Surprising Connections (you probably didn't know these)
- `ExecuteAsyncQuery()` --calls--> `GetDb()`  [INFERRED]
  ext/go_snowflake/database/async.go → ext/go_snowflake/database/global.go
- `Fetch()` --calls--> `GetDb()`  [INFERRED]
  ext/go_snowflake/database/fetch.go → ext/go_snowflake/database/global.go
- `README` --conceptually_related_to--> `Changelog`  [INFERRED]
  README.md → CHANGELOG.md
- `Fetch()` --calls--> `AllocateColumnMemory()`  [INFERRED]
  ext/go_snowflake/go_snowflake.go → ext/go_snowflake/arguments_binding.go
- `AsyncExecute()` --calls--> `ConvertArgs()`  [INFERRED]
  ext/go_snowflake/go_snowflake.go → ext/go_snowflake/arguments_binding.go

## Import Cycles
- None detected.

## Communities (19 total, 9 thin omitted)

### Community 0 - "Go C Bridge Layer"
Cohesion: 0.17
Nodes (16): AllocateColumnMemory(), columnTypeToJSON(), ConvertArgs(), convertToCharArray(), SetColumnNamesAndTypes(), GetColumnTypes(), AsyncExecute(), CloseConnection() (+8 more)

### Community 1 - "Ruby Query Fetcher"
Cohesion: 0.14
Nodes (3): ArgumentBuilder, GoSnowflake, GoSnowflake::Fetcher

### Community 2 - "Go Connection Management"
Cohesion: 0.21
Nodes (10): ExecuteResult, Close(), Init(), loadPrivateKeyFromFile(), openDbDefault(), openDbWithPrivateKey(), Ping(), Execute() (+2 more)

### Community 3 - "Ruby Executor & Signals"
Cohesion: 0.12
Nodes (4): GoSnowflake, GoSnowflake::Executor, GoSnowflake, GoSnowflake::SignalHandler

### Community 4 - "Ruby Integration Tests"
Cohesion: 0.15
Nodes (5): connect(), GoSnowflakeRuby, GoSnowflakeRuby::ConnectionError, GoSnowflakeRuby::Database, GoSnowflakeRuby::Error

### Community 5 - "Ruby Database API"
Cohesion: 0.15
Nodes (4): TestConnectionStringEnv, TestGoSnowflakeRubyConnection, TestGoSnowflakeRubyDatabase, TestGoSnowflakeRubyGem

### Community 6 - "Go Cursor & Fetching"
Cohesion: 0.24
Nodes (6): Cursor, CloseCursor(), Fetch(), FetchNextRow(), formatValue(), newCursor()

### Community 7 - "Project Documentation"
Cohesion: 0.29
Nodes (8): Changelog, Code of Conduct, Contributor Covenant, GoSnowflakeRuby Module, GoSnowflakeRuby::Driver, MIT License, Mozilla Code of Conduct Enforcement Ladder, README

### Community 9 - "Ruby Error Definitions"
Cohesion: 0.33
Nodes (4): GoSnowflake, GoSnowflake::ConnectionError, GoSnowflake::Error, GoSnowflake::QueryError

### Community 11 - "Go Async Execution"
Cohesion: 0.60
Nodes (3): ExecuteAsyncResult, convertArgsToNamedValues(), ExecuteAsyncQuery()

## Knowledge Gaps
- **8 isolated node(s):** `GoSnowflakeRuby`, `ColumnTypeInfo`, `MIT License`, `Docker Compose Configuration`, `RuboCop Configuration` (+3 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 64 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GoSnowflakeRuby::Database` connect `Ruby Integration Tests` to `Ruby Database API`?**
  _High betweenness centrality (0.133) - this node is a cross-community bridge._
- **What connects `GoSnowflakeRuby`, `ColumnTypeInfo`, `MIT License` to the rest of the system?**
  _8 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Ruby Query Fetcher` be split into smaller, more focused modules?**
  _Cohesion score 0.14035087719298245 - nodes in this community are weakly interconnected._
- **Why does `GoSnowflake::Executor` connect `Ruby Executor & Signals` to `Ruby Query Fetcher`, `Ruby Integration Tests`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Should `Ruby Executor & Signals` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._
- **Why does `GetDb()` connect `Go Connection Management` to `Go Async Execution`, `Go Cursor & Fetching`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._