package database

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
)

var (
	ExecCancel context.CancelFunc
	ExecMu     sync.RWMutex
)

type ExecuteResult struct {
	LastInsertId int64
	RowsAffected int64
	Error        error
}

func CancelExecution() {
	ExecMu.Lock()
	defer ExecMu.Unlock()
	if ExecCancel != nil {
		ExecCancel()
	}
}

func Execute(query string, args []interface{}) ExecuteResult {
	db, err := GetDb()
	if err != nil {
		return ExecuteResult{Error: err}
	}
	ctx, cancel := context.WithCancel(context.Background())
	ExecMu.Lock()
	ExecCancel = cancel
	ExecMu.Unlock()

 	sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
    defer signal.Stop(sigChan)

    resultChan := make(chan ExecuteResult, 1)

    go func() {
        result, err := db.ExecContext(ctx, query, args...)
        executeResult := ExecuteResult{Error: err}

        if err == nil {
            lastInsertId, err := result.LastInsertId()
            if err == nil {
                executeResult.LastInsertId = lastInsertId
            }

            rowsAffected, err := result.RowsAffected()
            if err == nil {
                executeResult.RowsAffected = rowsAffected
            }
        }

        resultChan <- executeResult
    }()

    select {
    case sig := <-sigChan:
        cancel()
        return ExecuteResult{
            Error: fmt.Errorf("query cancelled by signal: %v", sig),
        }
    case result := <-resultChan:
        return result
    }
}
