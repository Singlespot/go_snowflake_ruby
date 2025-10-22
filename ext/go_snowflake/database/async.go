package database

import (
	"context"
	"database/sql/driver"
	"fmt"

	sf "github.com/snowflakedb/gosnowflake"
)

type ExecuteAsyncResult struct {
	Error   error
	QueryID string
}

func convertArgsToNamedValues(args []interface{}) []driver.NamedValue {
	namedArgs := make([]driver.NamedValue, len(args))
	for i, arg := range args {
		value, err := driver.DefaultParameterConverter.ConvertValue(arg)
		if err != nil {
			return nil
		}
		namedArgs[i] = driver.NamedValue{
			Name:    "",
			Ordinal: i + 1,
			Value:   value,
		}
	}
	return namedArgs
}

// ExecuteAsyncQuery executes a query asynchronously and returns the query ID
func ExecuteAsyncQuery(query string, args []interface{}) ExecuteAsyncResult {
    // Create context with timeout
    ctx := context.Background()

    // Set async mode
    ctx = sf.WithAsyncMode(ctx)

    // Get database connection
    db, err := GetDb()
    if err != nil {
        return ExecuteAsyncResult{Error: fmt.Errorf("failed to get database: %w", err)}
    }

    // Get connection with context
    conn, err := db.Conn(ctx)
    if err != nil {
        return ExecuteAsyncResult{Error: fmt.Errorf("failed to get connection: %w", err)}
    }
    defer conn.Close() // Ensure connection is closed

    var queryId string
    err = conn.Raw(func(x any) error {
        // Prepare statement with context
        stmt, err := x.(driver.ConnPrepareContext).PrepareContext(ctx, query)
        if err != nil {
            return fmt.Errorf("failed to prepare statement: %w", err)
        }
        defer stmt.Close()

        // Convert args
        namedArgs := convertArgsToNamedValues(args)
        if namedArgs == nil {
            return fmt.Errorf("failed to convert arguments")
        }

        // Execute with context
        _, err = stmt.(driver.StmtExecContext).ExecContext(ctx, namedArgs)
        if err != nil {
            return fmt.Errorf("failed to execute statement: %w", err)
        }

        // Get query ID
        if sfStmt, ok := stmt.(sf.SnowflakeStmt); ok {
            queryId = sfStmt.GetQueryID()
            if queryId == "" {
                return fmt.Errorf("got empty query ID")
            }
        } else {
            return fmt.Errorf("statement does not implement SnowflakeStmt")
        }

        return nil
    })

    if err != nil {
        return ExecuteAsyncResult{Error: err}
    }

    return ExecuteAsyncResult{
        Error:   nil,
        QueryID: queryId,
    }
}
