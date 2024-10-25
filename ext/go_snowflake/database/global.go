package database

import "C"
import (
	"database/sql"
	"fmt"
	"sync"

	_ "github.com/snowflakedb/gosnowflake"
)

var (
	db       *sql.DB
	dbMu     sync.RWMutex
	initOnce sync.Once
)

func setDb(database *sql.DB) {
	dbMu.Lock()
	defer dbMu.Unlock()
	db = database
}

func GetDb() (*sql.DB, error) {
	dbMu.RLock()
	defer dbMu.RUnlock()

	if db == nil {
		return nil, fmt.Errorf("database connection not initialized")
	}
	return db, nil
}
