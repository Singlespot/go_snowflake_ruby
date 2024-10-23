package database

import "C"
import (
	"database/sql"
	"fmt"

	_ "github.com/snowflakedb/gosnowflake"
)

var db *sql.DB

func SetDb(_db *sql.DB) {
	db = _db
}

func GetDb() (*sql.DB, error) {
	if db == nil {
		return nil, fmt.Errorf("Database has not been initialised")
	}
	return db, nil
}
