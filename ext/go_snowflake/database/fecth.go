package database

import (
	"database/sql"
	"errors"
	"fmt"
	"sync"
	"time"
)

var (
	ErrNoCursor = errors.New("no cursor available")
	ErrNilDB    = errors.New("database connection is nil")
)

type Cursor struct {
	rows   *sql.Rows
	mutex  sync.Mutex
	closed bool
}

var (
	currentCursor *Cursor
	cursorMutex   sync.RWMutex
)

const (
	NullValue      = "NULL"
	defaultTimeout = 30 * time.Second
)

// newCursor creates a new cursor instance
func newCursor(rows *sql.Rows) *Cursor {
	return &Cursor{
		rows:   rows,
		closed: false,
	}
}

// Fetch executes a query and stores the result in a cursor
func Fetch(query string, args []interface{}) error {
	cursorMutex.Lock()
	defer cursorMutex.Unlock()

	// Close any existing cursor
	if currentCursor != nil {
		CloseCursor()
	}

	db, err := GetDb()
	if err != nil {
		return fmt.Errorf("failed to get database connection: %w", err)
	}

	if db == nil {
		return ErrNilDB
	}

	rows, err := db.Query(query, args...)
	if err != nil {
		return fmt.Errorf("failed to execute query: %w", err)
	}

	currentCursor = newCursor(rows)
	return nil
}

// GetColumns returns the column names of the current result set
func GetColumns() ([]string, error) {
	cursorMutex.RLock()
	defer cursorMutex.RUnlock()

	if currentCursor == nil || currentCursor.rows == nil {
		return nil, ErrNoCursor
	}
	return currentCursor.rows.Columns()
}

// GetColumnTypes returns the column types of the current result set
func GetColumnTypes() ([]*sql.ColumnType, error) {
	cursorMutex.RLock()
	defer cursorMutex.RUnlock()

	if currentCursor == nil || currentCursor.rows == nil {
		return nil, ErrNoCursor
	}
	return currentCursor.rows.ColumnTypes()
}

// FetchNextRow fetches the next row from the result set
func FetchNextRow() ([]string, error) {
	if currentCursor == nil {
		return nil, ErrNoCursor
	}

	currentCursor.mutex.Lock()
	defer currentCursor.mutex.Unlock()

	if currentCursor.closed {
		return nil, ErrNoCursor
	}

	if !currentCursor.rows.Next() {
		if err := currentCursor.rows.Err(); err != nil {
			return nil, fmt.Errorf("error advancing cursor: %w", err)
		}
		return nil, nil
	}

	cols, err := currentCursor.rows.Columns()
	if err != nil {
		return nil, fmt.Errorf("error getting columns: %w", err)
	}

	values := make([]interface{}, len(cols))
	scanArgs := make([]interface{}, len(cols))
	for i := range values {
		scanArgs[i] = &values[i]
	}

	if err := currentCursor.rows.Scan(scanArgs...); err != nil {
		return nil, fmt.Errorf("error scanning row: %w", err)
	}

	row := make([]string, len(cols))
	for i, val := range values {
		row[i] = formatValue(val)
	}

	return row, nil
}

// formatValue converts a value to its string representation
func formatValue(val interface{}) string {
	if val == nil {
		return NullValue
	}
	return fmt.Sprintf("%v", val)
}

// CloseCursor closes the current cursor and cleans up resources
func CloseCursor() error {
	cursorMutex.Lock()
	defer cursorMutex.Unlock()

	if currentCursor == nil {
		return nil
	}

	currentCursor.mutex.Lock()
	defer currentCursor.mutex.Unlock()

	if !currentCursor.closed && currentCursor.rows != nil {
		if err := currentCursor.rows.Close(); err != nil {
			return fmt.Errorf("error closing cursor: %w", err)
		}
		currentCursor.closed = true
	}

	currentCursor = nil
	return nil
}

// IsCursorOpen returns whether there is an open cursor
func IsCursorOpen() bool {
	cursorMutex.RLock()
	defer cursorMutex.RUnlock()
	return currentCursor != nil && !currentCursor.closed
}
