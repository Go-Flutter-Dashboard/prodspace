package config

import (
	"github.com/rs/zerolog/log"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	AppEnv     string `envconfig:"APP_ENV"     default:"DEV" required:"true"`
	Secret     string `envconfig:"AUTH_SECRET" default:"secret" required:"true"`
	JwtSecret  string `envconfig:"JWT_SECRET"  default:"secret" required:"true"`
	DbHost     string `envconfig:"DB_HOST"     default:"localhost" required:"true"`
	DbUser     string `envconfig:"DB_USER"     default:"postgres" required:"true"`
	DbPassword string `envconfig:"DB_PASSWORD" default:"postgres" required:"true"`
	DbName     string `envconfig:"DB_NAME"     default:"prodboardDB" required:"true"`
	DbPort     string `envconfig:"DB_PORT"     default:"5432" required:"true"`
}

var C Config

func init() {
	// does not override set env variables
	err := godotenv.Load()
	if err != nil {
		log.Warn().Msg("failed to load .env; using set env vars")
	}
	if err := envconfig.Process("", &C); err != nil {
		panic(err) // invalid env file
	}
}
