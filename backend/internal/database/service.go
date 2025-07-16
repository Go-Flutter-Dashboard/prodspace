package database

import (
	"backend/config"
	"backend/internal/database/schemas"

	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/dgrijalva/jwt-go"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"gorm.io/gorm/logger"
)

var DB *gorm.DB

var (
	secret     = config.C.Secret
	jwtSecret  = config.C.JwtSecret
	dbHost     = config.C.DbHost
	dbUser     = config.C.DbUser
	dbPassword = config.C.DbPassword
	dbName     = config.C.DbName
	dbPort     = config.C.DbPort
)

func Hash(login, password string) string {
	data := login + ":" + password + ":" + secret
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

func VerifyPassword(storedHash, login, inputPassword string) bool {
    inputHash := Hash(login, inputPassword)
    return subtle.ConstantTimeCompare([]byte(storedHash), []byte(inputHash)) == 1
}

func CreateTokenForUser(user schemas.User) (string, error) {
	claims := jwt.MapClaims{
		"id":    user.ID,
		"login": user.Login,
		"role":  "user",
		"exp":   time.Now().Add(time.Hour * 72).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtSecret))
}

func InitDatabase() error {
	var err error

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable",
		dbHost, dbUser, dbPassword, dbName, dbPort,
	)

	switch config.C.AppEnv {
	case "PROD":
		DB, err = gorm.Open(
			postgres.Open(dsn),
			&gorm.Config{
				TranslateError: true,                                  // fix to properly return errors
				Logger:         logger.Default.LogMode(logger.Silent), // silence the gorm logger
			},
		)
		// DB = DB.Debug() // debug postgres queries if needed
	case "DEV":
		DB, err = gorm.Open(
			sqlite.Open("devDb.db"),
			&gorm.Config{
				TranslateError: true, // fix to properly return errors
				// Logger: logger.Default.LogMode(logger.Silent), // silence the gorm logger
			},
		)
		DB = DB.Debug() // outputs generated sql to stdout
	}

	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	err = DB.AutoMigrate(
		&schemas.User{},
		&schemas.ImageItem{},
		&schemas.Item{},
		&schemas.TextItem{},
		&schemas.TodoListField{},
		&schemas.TodoListItem{},
	)
	
	if err != nil {
		return fmt.Errorf("failed to migrate database: %w", err)
	}
	
	return nil
}

