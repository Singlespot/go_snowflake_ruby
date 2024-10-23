package main

import "C"

import (

	//Why do I have to import twice?
	database "go_snowflake/go_snowflake/database"

	_ "github.com/snowflakedb/gosnowflake"
)

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

//export Fetch
func Fetch(
	query *C.char,
	outColumns **C.char,
	outColumnTypes **C.char,
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
	err := database.Fetch(gquery, goArgs)
	if err != nil {
		return cStringFromError(err)
	}
	columns, err := database.GetColumns()
	if err != nil {
		return cStringFromError(err)
	}
	numCols := len(columns)
	*outCols = C.int(numCols)
	columnTypes, err := database.GetColumnTypes()
	if err != nil {
		return cStringFromError(err)
	}
	// Allocate memory for column names and types
	colNames, colTypes := AllocateColumnMemory(numCols, outColumns, outColumnTypes)

	// Set column names and types
	SetColumnNamesAndTypes(columns, columnTypes, colNames, colTypes, outColumns, outColumnTypes)
	return nil
}

//export FetchNextRow
func FetchNextRow(isOver *C.uchar, outValues **C.char, numCols int) *C.char {
	value, err := database.FetchNextRow()
	if err != nil {
		return cStringFromError(err)
	}
	if value == nil {
		*isOver = 1
	} else {
		*isOver = 0
	}
	convertToCharArray(value, outValues)
	return nil
}

//export CloseCursor
func CloseCursor() {
	database.CloseCursor()
}

//export Execute
func Execute(query *C.char, lastId *C.int, rowsNb *C.int, args **C.char, argTypes *C.int, argsCount C.int) *C.char {
	// Convert the query and argumentss to Go types
	gquery := C.GoString(query)
	// Convert the arguments to Go types
	goArgs, errMsg := ConvertArgs(args, argTypes, argsCount)
	if errMsg != nil {
		return errMsg
	}
	execRes := database.Execute(gquery, goArgs)
	if execRes.Error != nil {
		return cStringFromError(execRes.Error)
	}
	*lastId = C.int(execRes.LastInsertId)
	*rowsNb = C.int(execRes.RowsAffected)
	return nil
}

func main() {

}
