package main

import "C"
import (
	"database/sql"
	"fmt"
	"unsafe"

	_ "github.com/snowflakedb/gosnowflake"
)

var db *sql.DB

const NullValue = "NULL"

// cStringFromError converts Go error messages to C strings
func cStringFromError(err error) *C.char {
	if err == nil {
		return nil
	}
	return C.CString(err.Error())
}

//export InitConnection
func InitConnection(conn_str *C.char) *C.char {
	gconn_str := C.GoString(conn_str)
	var err error
	db, err = sql.Open("snowflake", gconn_str)
	if err != nil {
		return cStringFromError(err)
	}
	err = db.Ping()
	if err != nil {
		return C.CString(fmt.Sprintf("Failed to ping database: %v", err))
	}
	return Ping()
}

//export Ping
func Ping() *C.char {
	if db == nil {
		return C.CString(fmt.Sprintf("Database has not be initialise"))
	}
	err := db.Ping()
	if err != nil {
		return C.CString(fmt.Sprintf("Failed to ping database: %v", err))
	}
	return nil
}

//export CloseConnection
func CloseConnection() {
	if db != nil {
		db.Close()
	}
}

func allocateColumnMemory(numCols int, outColumns **C.char, outColumnTypes **C.char) ([]*C.char, []*C.char) {
	colNames := make([]*C.char, numCols)
	colTypes := make([]*C.char, numCols)

	*outColumns = (*C.char)(C.malloc(C.size_t(numCols) * C.size_t(unsafe.Sizeof(uintptr(0)))))
	*outColumnTypes = (*C.char)(C.malloc(C.size_t(numCols) * C.size_t(unsafe.Sizeof(uintptr(0)))))

	return colNames, colTypes
}

func setColumnNamesAndTypes(columns []string, columnTypes []*sql.ColumnType, colNames []*C.char, colTypes []*C.char, outColumns **C.char, outColumnTypes **C.char) {
	for i, col := range columns {
		colNames[i] = C.CString(col)
		colTypes[i] = C.CString(columnTypes[i].DatabaseTypeName())

		// Set column names
		ptrName := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(*outColumns)) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptrName = colNames[i]

		// Set column types
		ptrType := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(*outColumnTypes)) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptrType = colTypes[i]
	}
}

func readRows(rows *sql.Rows, numCols int) ([][]string, error) {
	var results [][]string
	for rows.Next() {
		values := make([]interface{}, numCols)
		valuePtrs := make([]interface{}, numCols)
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		// Scan the row into value pointers
		err := rows.Scan(valuePtrs...)
		if err != nil {
			return nil, err
		}

		// Convert the scanned values to strings
		row := make([]string, numCols)
		for i, val := range values {
			if val != nil {
				row[i] = fmt.Sprintf("%v", val)
			} else {
				row[i] = NullValue
			}
		}
		results = append(results, row)
	}
	return results, nil
}

func allocateRowMemory(results [][]string, numCols int, outValues ***C.char) {
	numRows := len(results)
	*outValues = (**C.char)(C.malloc(C.size_t(numRows) * C.size_t(unsafe.Sizeof(uintptr(0)))))

	for i := 0; i < numRows; i++ {
		row := results[i]
		rowArray := (*C.char)(C.malloc(C.size_t(numCols) * C.size_t(unsafe.Sizeof(uintptr(0)))))
		for j := 0; j < numCols; j++ {
			ptr := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(rowArray)) + uintptr(j)*unsafe.Sizeof(uintptr(0))))
			*ptr = C.CString(row[j])
		}
		ptr := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(*outValues)) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptr = rowArray
	}
}

//export Fetch
func Fetch(query *C.char, outColumns **C.char, outValues ***C.char, outColumnTypes **C.char, outRows *C.int, outCols *C.int) *C.char {
	//Ugly need refacto
	gquery := C.GoString(query)

	// Execute the query
	rows, err := db.Query(gquery)
	if err != nil {
		return cStringFromError(err)
	}
	defer rows.Close()

	// Get column names and column count
	columns, err := rows.Columns()
	if err != nil {
		return cStringFromError(err)
	}
	numCols := len(columns)
	*outCols = C.int(numCols)

	// Get column types
	columnTypes, err := rows.ColumnTypes()
	if err != nil {
		return cStringFromError(err)
	}

	// Allocate memory for column names and types
	colNames, colTypes := allocateColumnMemory(numCols, outColumns, outColumnTypes)

	// Set column names and types
	setColumnNamesAndTypes(columns, columnTypes, colNames, colTypes, outColumns, outColumnTypes)

	// Prepare for reading rows
	results, err := readRows(rows, numCols)
	if err != nil {
		return C.CString(fmt.Sprintf("Error scanning row: %v", err))
	}

	// Set number of rows
	numRows := len(results)
	*outRows = C.int(numRows)

	// Allocate memory for row values
	allocateRowMemory(results, numCols, outValues)

	return nil
}

func main() {

}
