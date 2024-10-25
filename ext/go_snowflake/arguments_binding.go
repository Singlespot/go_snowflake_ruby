package main

import "C"

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strconv"
	"unsafe"
)

// ArgType represents the type of an argument
type ArgType int

const (
	ArgTypeString ArgType = iota
	ArgTypeInt
	// Add more types as needed
)

type ColumnTypeInfo struct {
	TypeName  string
	Length    int64
	Precision int64
	Scale     int64
	Nullable  bool
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

func AllocateColumnMemory(numCols int, outColumns **C.char, outColumnTypes **C.char) ([]*C.char, []*C.char) {
	colNames := make([]*C.char, numCols)
	colTypes := make([]*C.char, numCols)

	*outColumns = (*C.char)(C.malloc(C.size_t(numCols) * C.size_t(unsafe.Sizeof(uintptr(0)))))
	*outColumnTypes = (*C.char)(C.malloc(C.size_t(numCols) * C.size_t(unsafe.Sizeof(uintptr(0)))))

	return colNames, colTypes
}

func columnTypeToJSON(ct *sql.ColumnType) string {
	info := ColumnTypeInfo{
		TypeName: ct.DatabaseTypeName(),
		Nullable: true, // default value
	}

	// Get length for variable length types
	length, ok := ct.Length()
	if ok {
		info.Length = length
	}

	// Get precision and scale for decimal types
	precision, scale, ok := ct.DecimalSize()
	if ok {
		info.Precision = precision
		info.Scale = scale
	}

	// Get nullable property
	nullable, ok := ct.Nullable()
	if ok {
		info.Nullable = nullable
	}

	jsonBytes, err := json.Marshal(info)
	if err != nil {
		return "{}"
	}
	return string(jsonBytes)
}

func SetColumnNamesAndTypes(columns []string, columnTypes []*sql.ColumnType, colNames []*C.char, colTypes []*C.char, outColumns **C.char, outColumnTypes **C.char) {
	for i, col := range columns {
		colNames[i] = C.CString(col)
		// colTypes[i] = C.CString(columnTypes[i].DatabaseTypeName())
		colTypes[i] = C.CString(columnTypeToJSON(columnTypes[i]))

		// Set column names
		ptrName := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(*outColumns)) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptrName = colNames[i]

		// Set column types
		ptrType := (**C.char)(unsafe.Pointer(uintptr(unsafe.Pointer(*outColumnTypes)) + uintptr(i)*unsafe.Sizeof(uintptr(0))))
		*ptrType = colTypes[i]
	}
}

func convertToCharArray(values []string, outValues **C.char) {
	// Allocate memory for the array of C string pointers
	cArray := C.malloc(C.size_t(len(values)) * C.size_t(unsafe.Sizeof(uintptr(0))))

	// Convert each string and set in the array
	for i, s := range values {
		cStr := C.CString(s)
		// Set the pointer directly
		*(**C.char)(unsafe.Pointer(uintptr(cArray) + uintptr(i)*unsafe.Sizeof(uintptr(0)))) = cStr
	}

	// Set the output parameter
	*outValues = (*C.char)(cArray)
}
