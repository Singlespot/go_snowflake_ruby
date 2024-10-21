package main

import "C"
import (
	"database/sql"
	"fmt"
	"strconv"
	"unsafe"

	//Why do I have to import twice?
	database "go_snowflake/go_snowflake/database"

	_ "github.com/snowflakedb/gosnowflake"
)

// ArgType represents the type of an argument
type ArgType int

const (
	ArgTypeString ArgType = iota
	ArgTypeInt
	// Add more types as needed
)

const NullValue = "NULL"

// cStringFromError converts Go error messages to C strings
func cStringFromError(err error) *C.char {
	if err == nil {
		return nil
	}
	return C.CString(err.Error())
}

//export Ping
func Ping() *C.char {
	err := database.Ping()
	if err != nil {
		return cStringFromError(err)
	}
	return nil
}

//export InitConnection
func InitConnection(conn_str *C.char) *C.char {
	gconn_str := C.GoString(conn_str)
	err := database.Init(gconn_str)
	if err != nil {
		return cStringFromError(err)
	}
	return nil
}

//export CloseConnection
func CloseConnection() *C.char {
	err := database.Close()
	if err != nil {
		return cStringFromError(err)
	}
	return nil
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

func ConvertArgs(args **C.char, argTypes *C.int, argsCount C.int) ([]interface{}, *C.char) {
	goArgs := make([]interface{}, argsCount)
	argTypesSlice := unsafe.Slice(argTypes, argsCount)
	argsSlice := unsafe.Slice(args, argsCount)

	for i := 0; i < int(argsCount); i++ {
		argType := ArgType(argTypesSlice[i])
		argValue := C.GoString(argsSlice[i])

		switch argType {
		case ArgTypeInt:
			intVal, err := strconv.Atoi(argValue)
			if err != nil {
				return nil, C.CString(fmt.Sprintf("Error converting argument %d to integer: %v", i, err))
			}
			goArgs[i] = intVal
		case ArgTypeString:
			goArgs[i] = argValue
		// Add more cases for other types as needed
		default:
			return nil, C.CString(fmt.Sprintf("Unknown argument type %d for argument %d", int(argType), i))
		}
	}

	return goArgs, nil
}

//export Fetch
func Fetch(query *C.char,
	outColumns **C.char,
	outValues ***C.char,
	outColumnTypes **C.char,
	outRows *C.int,
	outCols *C.int,
	args **C.char,
	argTypes *C.int,
	argsCount C.int) *C.char {
	// Convert the query and arguments to Go types
	gquery := C.GoString(query)
	// Convert the arguments to Go types
	goArgs, errMsg := ConvertArgs(args, argTypes, argsCount)
	if errMsg != nil {
		return errMsg
	}
	// Get the database connection
	db, err := database.GetDb()
	if err != nil {
		return cStringFromError(err)
	}
	// Execute the query
	rows, err := db.Query(gquery, goArgs...)
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

//export Execute
func Execute(query *C.char, lastId *C.int, rowsNb *C.int, args **C.char, argTypes *C.int, argsCount C.int) *C.char {
	// Convert the query and arguments to Go types
	gquery := C.GoString(query)
	// Convert the arguments to Go types
	goArgs, errMsg := ConvertArgs(args, argTypes, argsCount)
	if errMsg != nil {
		return errMsg
	}
	// Get the database connection
	db, err := database.GetDb()
	if err != nil {
		return cStringFromError(err)
	}
	// Execute the query
	res, err := db.Exec(gquery, goArgs...)
	if err != nil {
		return cStringFromError(err)
	}
	// Get the number of rows affected
	rows, err := res.RowsAffected()
	if err != nil {
		return cStringFromError(err)
	}
	// Get the last inserted ID
	lastInsertedId, err := res.LastInsertId()
	// Set the output values
	*lastId = C.int(lastInsertedId)
	*rowsNb = C.int(rows)

	return nil
}

func main() {

}
