package database

import "C"
import (
	"database/sql"
	"errors"
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
		return errors.New(fmt.Sprintf("Failed to ping database: %v", err))
	}
	return nil
}

func Init(conn_str string) error {
	_db, err := sql.Open("snowflake", conn_str)
	if err != nil {
		return errors.New(fmt.Sprintf("Failed to open database: %v", err))
	}
	SetDb(_db)
	return Ping()
}

func Close() error {
	db, err := GetDb()
	if err != nil {
		return err
	}
	err = db.Close()
	if err != nil {
		return errors.New(fmt.Sprintf("Failed to close database: %v", err))
	}
	return nil
}
