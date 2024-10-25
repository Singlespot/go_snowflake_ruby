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
	var initErr error
	initOnce.Do(func() {
		database, err := sql.Open("snowflake", connStr)
		if err != nil {
			initErr = fmt.Errorf("failed to open database: %w", err)
			return
		}

		if err := database.Ping(); err != nil {
			database.Close()
			initErr = fmt.Errorf("failed to ping database: %w", err)
			return
		}

		setDb(database)
	})
	return initErr
}

func Close() error {
	db, err := GetDb()
	if err != nil {
		return err
	}
	err = db.Close()
	if err != nil {
		return fmt.Errorf("failed to close database: %w", err)
	}
	return nil
}
