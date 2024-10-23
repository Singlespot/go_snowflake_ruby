package database

type ExecuteResult struct {
	LastInsertId int64
	RowsAffected int64
	Error        error
}

func Execute(query string, args []interface{}) ExecuteResult {
	db, err := GetDb()
	if err != nil {
		return ExecuteResult{Error: err}
	}
	// Execute the query
	res, err := db.Exec(query, args...)
	if err != nil {
		return ExecuteResult{Error: err}
	}
	// Get the number of rows affected
	rows, err := res.RowsAffected()
	if err != nil {
		return ExecuteResult{Error: err}
	}
	// Get the last inserted ID
	lastInsertedId, err := res.LastInsertId()
	if err != nil {
		return ExecuteResult{Error: err}
	}
	return ExecuteResult{LastInsertId: lastInsertedId, RowsAffected: rows}
}
