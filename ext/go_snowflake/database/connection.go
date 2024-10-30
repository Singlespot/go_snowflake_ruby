package database

import "C"
import (
	"database/sql"
	"fmt"

	_ "github.com/snowflakedb/gosnowflake"
)

func Ping() error {
	db, err := GetDb()
	if err != nil {
		return err
	}
	err = db.Ping()
	if err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}
	return nil
}

func Init(connStr string) error {
	dbMu.Lock()
	defer dbMu.Unlock()

	// Close existing connection if it exists
	if db != nil {
		if err := db.Close(); err != nil {
			return fmt.Errorf("failed to close existing connection: %w", err)
		}
		db = nil
	}

	// Create new connection
	database, err := sql.Open("snowflake", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database: %w", err)
	}

	// Test the connection
	if err := database.Ping(); err != nil {
		database.Close()
		return fmt.Errorf("failed to ping database: %w", err)
	}

	db = database // directly set db since we already have the lock
	return nil
}

func Close() error {
	dbMu.Lock()
	defer dbMu.Unlock()

	if db != nil {
		err := db.Close()
		if err != nil {
			return fmt.Errorf("failed to close database: %w", err)
		}
		db = nil // Clear the connection after closing
	}
	return nil
}
