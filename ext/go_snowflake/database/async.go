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

	ctx := context.Background()

	db, err := GetDb()
	if err != nil {
		return ExecuteAsyncResult{Error: err}
	}

	conn, err := db.Conn(ctx)
	if err != nil {
		return ExecuteAsyncResult{Error: err}
	}

	var queryId string
	err2 := conn.Raw(
		func(x any) error {
			stmt, err := x.(driver.ConnPrepareContext).PrepareContext(ctx, query)
			if err != nil {
				return err
			}
			defer stmt.Close()
			// Convert args from []interface{} to []driver.NamedValue
			namedArgs := convertArgsToNamedValues(args)

			_, err = stmt.(driver.StmtExecContext).ExecContext(ctx, namedArgs)
			if err != nil {
				return err
			}
			if sfStmt, ok := stmt.(sf.SnowflakeStmt); ok {
				queryId = sfStmt.GetQueryID()
			} else {
				return fmt.Errorf("Statement does not implement SnowflakeStmt")
			}
			return nil
		})
	if err2 != nil {
		return ExecuteAsyncResult{Error: err2}
	} else {
		return ExecuteAsyncResult{Error: nil, QueryID: queryId}
	}
}
