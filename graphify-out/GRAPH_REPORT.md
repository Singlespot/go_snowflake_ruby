# Graph Report - go_snowflake_ruby  (2026-09-10)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 164 nodes · 217 edges · 19 communities (11 shown, 5 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.82)
- Token cost: 92,356 input · 1,557 output

## Graph Freshness
- Built from commit: `02378202`
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
- Setup Script
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
- `README` --conceptually_related_to--> `Changelog`  [INFERRED]
  README.md → CHANGELOG.md
- `README` --references--> `MIT License`  [EXTRACTED]
  README.md → LICENSE.txt
- `ExecuteAsyncQuery()` --calls--> `GetDb()`  [INFERRED]
  ext/go_snowflake/database/async.go → ext/go_snowflake/database/global.go
- `Fetch()` --calls--> `GetDb()`  [INFERRED]
  ext/go_snowflake/database/fetch.go → ext/go_snowflake/database/global.go
- `README` --references--> `Code of Conduct`  [EXTRACTED]
  README.md → CODE_OF_CONDUCT.md

## Import Cycles
- None detected.

## Communities (19 total, 5 thin omitted)

### Community 0 - "Go C Bridge Layer"
Cohesion: 0.17
Nodes (20): AllocateColumnMemory(), columnTypeToJSON(), ConvertArgs(), convertToCharArray(), SetColumnNamesAndTypes(), GetColumnTypes(), AsyncExecute(), CloseConnection() (+12 more)

### Community 1 - "Ruby Query Fetcher"
Cohesion: 0.13
Nodes (4): ArgumentBuilder, GoSnowflake, GoSnowflake::Fetcher, BaseExecutor

### Community 2 - "Go Connection Management"
Cohesion: 0.21
Nodes (13): ExecuteResult, Close(), Init(), loadPrivateKeyFromFile(), openDbDefault(), openDbWithPrivateKey(), Ping(), Execute() (+5 more)

### Community 3 - "Ruby Executor & Signals"
Cohesion: 0.12
Nodes (5): GoSnowflake, GoSnowflake::Executor, BaseExecutor, GoSnowflake, GoSnowflake::SignalHandler

### Community 4 - "Ruby Integration Tests"
Cohesion: 0.15
Nodes (5): Test, TestConnectionStringEnv, TestGoSnowflakeRubyConnection, TestGoSnowflakeRubyDatabase, TestGoSnowflakeRubyGem

### Community 5 - "Ruby Database API"
Cohesion: 0.16
Nodes (7): connect(), GoSnowflakeRuby, GoSnowflakeRuby::ConnectionError, GoSnowflakeRuby::Database, GoSnowflakeRuby::Error, Error, StandardError

### Community 6 - "Go Cursor & Fetching"
Cohesion: 0.24
Nodes (8): Cursor, CloseCursor(), Fetch(), FetchNextRow(), formatValue(), newCursor(), database/sql.Rows, sync.Mutex

### Community 7 - "Project Documentation"
Cohesion: 0.29
Nodes (8): Changelog, Code of Conduct, Contributor Covenant, GoSnowflakeRuby Module, GoSnowflakeRuby::Driver, MIT License, Mozilla Code of Conduct Enforcement Ladder, README

### Community 9 - "Ruby Error Definitions"
Cohesion: 0.33
Nodes (6): GoSnowflake, GoSnowflake::ConnectionError, GoSnowflake::Error, GoSnowflake::QueryError, Error, StandardError

### Community 10 - "Ruby Async Executor"
Cohesion: 0.33
Nodes (3): GoSnowflake, GoSnowflake::AsyncExecutor, BaseExecutor

### Community 11 - "Go Async Execution"
Cohesion: 0.60
Nodes (4): ExecuteAsyncResult, convertArgsToNamedValues(), ExecuteAsyncQuery(), database/sql/driver.NamedValue

## Knowledge Gaps
- **8 isolated node(s):** `GoSnowflakeRuby`, `ColumnTypeInfo`, `MIT License`, `Docker Compose Configuration`, `RuboCop Configuration` (+3 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 64 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GoSnowflakeRuby::Database` connect `Ruby Database API` to `Ruby Query Fetcher`, `Ruby Integration Tests`?**
  _High betweenness centrality (0.133) - this node is a cross-community bridge._
- **Why does `GoSnowflake::Executor` connect `Ruby Executor & Signals` to `Ruby Query Fetcher`, `Ruby Database API`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Why does `GetDb()` connect `Go Connection Management` to `Go Async Execution`, `Go Cursor & Fetching`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **What connects `GoSnowflakeRuby`, `ColumnTypeInfo`, `MIT License` to the rest of the system?**
  _8 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Ruby Query Fetcher` be split into smaller, more focused modules?**
  _Cohesion score 0.13157894736842105 - nodes in this community are weakly interconnected._
- **Should `Ruby Executor & Signals` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._