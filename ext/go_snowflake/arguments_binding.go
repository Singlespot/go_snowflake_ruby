package main

import "C"

import (
	"database/sql"
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

func SetColumnNamesAndTypes(columns []string, columnTypes []*sql.ColumnType, colNames []*C.char, colTypes []*C.char, outColumns **C.char, outColumnTypes **C.char) {
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
