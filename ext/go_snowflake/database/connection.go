package database

import "C"

import (
	"fmt"
	"database/sql"
	"crypto/rsa"
	"encoding/pem"
	"crypto/x509"
	"net/url"
	"errors"
	"io/ioutil"

	"github.com/snowflakedb/gosnowflake"
)

func loadPrivateKeyFromFile(path string) (*rsa.PrivateKey, error) {
    pemBytes, err := ioutil.ReadFile(path)
    if err != nil {
        return nil, err
    }
    block, _ := pem.Decode(pemBytes)
    if block == nil {
        return nil, errors.New("failed to decode PEM block")
    }
    parsedKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
    if err != nil {
        return nil, err
    }
    return parsedKey.(*rsa.PrivateKey), nil
}

func Ping() error {
	db, err := GetDb()
	if err != nil {
		return err
	}
	err = db.Ping()
	if err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}
	return nil
}

func openDbWithPrivateKey(u *url.URL, privateKeyPath string) (*sql.DB, error) {
    // Remove privateKeyParse from query
    q := u.Query()
    q.Del("privateKeyParse")
    u.RawQuery = q.Encode()

    // Parse DSN
    cfg, err := gosnowflake.ParseDSN(u.String())
    if err != nil {
        return nil, fmt.Errorf("failed to parse DSN: %w", err)
    }

    // Load and parse private key
    rsaKey, err := loadPrivateKeyFromFile(privateKeyPath)
    if err != nil {
        return nil, fmt.Errorf("failed to load private key: %w", err)
    }
    cfg.Authenticator = gosnowflake.AuthTypeJwt
    cfg.PrivateKey = rsaKey

    dsn, err := gosnowflake.DSN(cfg)
    if err != nil {
        return nil, fmt.Errorf("failed to create DSN: %w", err)
    }
    database, err := sql.Open("snowflake", dsn)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }
    if err := database.Ping(); err != nil {
        database.Close()
        return nil, fmt.Errorf("failed to ping database: %w", err)
    }
    return database, nil
}

func openDbDefault(connStr string) (*sql.DB, error) {
    database, err := sql.Open("snowflake", connStr)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }
    if err := database.Ping(); err != nil {
        database.Close()
        return nil, fmt.Errorf("failed to ping database: %w", err)
    }
    return database, nil
}

func Init(connStr string) error {
    dbMu.Lock()
    defer dbMu.Unlock()

    // Close existing connection if it exists
    if db != nil {
        if err := db.Close(); err != nil {
            return fmt.Errorf("failed to close existing connection: %w", err)
        }
        db = nil
    }

    u, err := url.Parse(connStr)
    if err != nil {
        return fmt.Errorf("failed to parse connection string: %w", err)
    }
    q := u.Query()
    privateKeyPath := q.Get("privateKeyPath")
    if privateKeyPath != "" {
        database, err := openDbWithPrivateKey(u, privateKeyPath)
        if err != nil {
            return err
        }
        db = database
        return nil
    }

    database, err := openDbDefault(connStr)
    if err != nil {
        return err
    }
    db = database
    return nil
}

func Close() error {
	dbMu.Lock()
	defer dbMu.Unlock()

	if db != nil {
		err := db.Close()
		if err != nil {
			return fmt.Errorf("failed to close database: %w", err)
		}
		db = nil // Clear the connection after closing
	}
	return nil
}
