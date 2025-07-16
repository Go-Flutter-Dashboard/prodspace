package handlers

import (
	"backend/config"
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/models"
	"bytes"
	"encoding/json"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupTestDB() *gorm.DB {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{TranslateError: true})
	if err != nil {
		panic("failed to connect test database")
	}

	// Migrate the schema
	db.AutoMigrate(&schemas.User{}, &schemas.Workspace{})
	return db
}

func TestRegisterUser(t *testing.T) {
	// Setup
	app := fiber.New()
	testDB := setupTestDB()
	originalDB := database.DB // Save original DB
	database.DB = testDB      // Replace with test DB
	defer func() {
		database.DB = originalDB // Restore original DB
	}()

	// Mock config
	config.C.JwtSecret = "test-secret"

	// Register route
	app.Post("/register", RegisterUser)

	tests := []struct {
		name           string
		payload        models.UserCreate
		expectedStatus int
		expectedError  string
		setup          func(*gorm.DB)
	}{
		{
			name: "Successful registration",
			payload: models.UserCreate{
				Login:    "testuser",
				Password: "testpass",
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Missing login",
			payload: models.UserCreate{
				Password: "testpass",
			},
			expectedStatus: fiber.StatusBadRequest,
			expectedError:  "login and password are required",
		},
		{
			name: "Missing password",
			payload: models.UserCreate{
				Login: "testuser",
			},
			expectedStatus: fiber.StatusBadRequest,
			expectedError:  "login and password are required",
		},
		{
			name: "Duplicate username",
			payload: models.UserCreate{
				Login:    "existinguser",
				Password: "testpass",
			},
			expectedStatus: fiber.StatusConflict,
			expectedError:  "username already exists",
			setup: func(db *gorm.DB) {
				db.Create(&schemas.User{
					Login:        "existinguser",
					PasswordHash: "hashedpassword",
				})
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup test data if needed
			if tt.setup != nil {
				tt.setup(testDB)
			}

			// Create request
			payloadBytes, _ := json.Marshal(tt.payload)
			req := httptest.NewRequest("POST", "/register", bytes.NewReader(payloadBytes))
			req.Header.Set("Content-Type", "application/json")

			// Make request
			resp, err := app.Test(req)
			assert.NoError(t, err)
			defer resp.Body.Close()

			// Check status code
			assert.Equal(t, tt.expectedStatus, resp.StatusCode)

			// Parse response
			var result map[string]interface{}
			json.NewDecoder(resp.Body).Decode(&result)

			if tt.expectedError != "" {
				// Check error message
				assert.Equal(t, tt.expectedError, result["error"])
			} else {
				// Check success response
				assert.Equal(t, "registration successful", result["message"])
				assert.NotEmpty(t, result["token"])
				assert.NotZero(t, result["user_id"])

				// Verify user was created in DB
				var user schemas.User
				testDB.Where("login = ?", tt.payload.Login).First(&user)
				assert.Equal(t, tt.payload.Login, user.Login)
				assert.NotEmpty(t, user.PasswordHash)

				// Verify workspace was created
				var workspace schemas.Workspace
				testDB.Where("user_id = ?", user.ID).First(&workspace)
				assert.Equal(t, user.ID, workspace.UserID)
			}
		})
	}
}

func TestGenerateJWTToken(t *testing.T) {
    // Setup
    config.C.JwtSecret = "test-secret"
    user := &schemas.User{
        ID:    1,
        Login: "testuser",
    }

    // Test token generation
    token, err := database.CreateTokenForUser(*user)
    assert.NoError(t, err)
    assert.NotEmpty(t, token)

    // Verify token contents
    parsedToken, err := jwt.Parse(token, func(t *jwt.Token) (interface{}, error) {
        if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fiber.ErrUnauthorized
        }
        return []byte(config.C.JwtSecret), nil
    })

    assert.NoError(t, err)
    assert.True(t, parsedToken.Valid)

    // Verify claims
    claims, ok := parsedToken.Claims.(jwt.MapClaims)
    assert.True(t, ok)

    // Check user ID
    assert.Equal(t, float64(user.ID), claims["id"]) // JWT numbers are float64
    assert.Equal(t, user.Login, claims["login"])

    // Check expiration exists and is in the future
    exp, ok := claims["exp"].(float64)
    assert.True(t, ok)
    assert.Greater(t, exp, float64(time.Now().Unix()))
}