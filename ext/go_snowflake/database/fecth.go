package database

import (
	"database/sql"
	"errors"
	"fmt"
	"sync"

	_ "github.com/snowflakedb/gosnowflake"
)

var (
	currentCursor *sql.Rows
	cursorMutex   sync.Mutex
)

const NullValue = "NULL"

func Fetch(query string, args []interface{}) error {
	cursorMutex.Lock()
	defer cursorMutex.Unlock()

	db, err := GetDb()
	if err != nil {
		return err
	}
	currentCursor, err = db.Query(query, args...)
	if err != nil {
		return err
	}
	return nil
}

func GetColumns() ([]string, error) {
	return currentCursor.Columns()
}

func GetColumnTypes() ([]*sql.ColumnType, error) {
	return currentCursor.ColumnTypes()
}

func FetchNextRow() ([]string, error) {
	cursorMutex.Lock()
	defer cursorMutex.Unlock()

	if currentCursor == nil {
		return nil, errors.New("No cursor available")
	}
	if !currentCursor.Next() {
		return nil, nil
	}

	cols, err := currentCursor.Columns()
	if err != nil {
		return nil, err
	}
	numCols := len(cols)
	values := make([]interface{}, numCols)
	valuePtrs := make([]interface{}, numCols)
	for i := range values {
		valuePtrs[i] = &values[i]
	}

	err = currentCursor.Scan(valuePtrs...)
	if err != nil {
		return nil, err
	}

	row := make([]string, numCols)
	for i, val := range values {
		if val != nil {
			row[i] = fmt.Sprintf("%v", val)
		} else {
			row[i] = NullValue
		}
	}
	return row, nil
}

func CloseCursor() {
	cursorMutex.Lock()
	defer cursorMutex.Unlock()

	if currentCursor != nil {
		currentCursor.Close()
		currentCursor = nil
	}
}
