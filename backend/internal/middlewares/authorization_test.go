package middleware

import (
	"backend/config"
	"backend/internal/database"
	"backend/internal/database/schemas"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
)

func TestJWTMiddleware(t *testing.T) {
	// Setup test user
	testUser := schemas.User{
		ID:           123,
		Login:        "testuser",
		PasswordHash: "hashedpassword",
	}

	// Override config
	config.C.JwtSecret = "test-secret-123"

	app := fiber.New()
	app.Use(JWTMiddleware)

	// Test endpoint to expose context values
	app.Get("/test", func(c *fiber.Ctx) error {
		response := struct {
			ID    uint   `json:"id"`
			Login string `json:"login"`
		}{}

		if val, ok := c.Locals(IDKey).(uint); ok {
			response.ID = val
		}
		if val, ok := c.Locals(LoginKey).(string); ok {
			response.Login = val
		}

		return c.JSON(response)
	})

	tests := []struct {
		name           string
		setupRequest  func() *http.Request
		expectedID     uint
		expectedLogin  string
		expectedStatus int
	}{
		{
			name: "No Authorization header",
			setupRequest: func() *http.Request {
				return httptest.NewRequest("GET", "/test", nil)
			},
			expectedID:     0,
			expectedLogin:  "",
			expectedStatus: fiber.StatusOK,
		},
		{
			name: "Valid JWT token",
			setupRequest: func() *http.Request {
				token, err := database.CreateTokenForUser(testUser)
				assert.NoError(t, err)
				
				req := httptest.NewRequest("GET", "/test", nil)
				req.Header.Set("Authorization", "Bearer "+token)
				return req
			},
			expectedID:     testUser.ID,
			expectedLogin:  testUser.Login,
			expectedStatus: fiber.StatusOK,
		},
		{
			name: "Expired JWT token",
			setupRequest: func() *http.Request {
				// Create expired token by modifying claims
				claims := jwt.MapClaims{
					"id":    testUser.ID,
					"login": testUser.Login,
					"role":  "user",
					"exp":   time.Now().Add(-time.Hour).Unix(), // Past time
				}
				token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
				tokenString, err := token.SignedString([]byte(config.C.JwtSecret))
				assert.NoError(t, err)
				
				req := httptest.NewRequest("GET", "/test", nil)
				req.Header.Set("Authorization", "Bearer "+tokenString)
				return req
			},
			expectedID:     0,
			expectedLogin:  "",
			expectedStatus: fiber.StatusOK,
		},
		{
			name: "Malformed JWT token",
			setupRequest: func() *http.Request {
				req := httptest.NewRequest("GET", "/test", nil)
				req.Header.Set("Authorization", "Bearer invalid.token.here")
				return req
			},
			expectedID:     0,
			expectedLogin:  "",
			expectedStatus: fiber.StatusOK,
		},
		{
			name: "Wrong signing method",
			setupRequest: func() *http.Request {
				claims := jwt.MapClaims{
					"id":    testUser.ID,
					"login": testUser.Login,
					"exp":   time.Now().Add(time.Hour).Unix(),
				}
				token := jwt.NewWithClaims(jwt.SigningMethodNone, claims)
				tokenString, err := token.SignedString(jwt.UnsafeAllowNoneSignatureType)
				assert.NoError(t, err)
				
				req := httptest.NewRequest("GET", "/test", nil)
				req.Header.Set("Authorization", "Bearer "+tokenString)
				return req
			},
			expectedID:     0,
			expectedLogin:  "",
			expectedStatus: fiber.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := tt.setupRequest()
			resp, err := app.Test(req)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedStatus, resp.StatusCode)

			var result struct {
				ID    uint   `json:"id"`
				Login string `json:"login"`
			}
			err = json.NewDecoder(resp.Body).Decode(&result)
			assert.NoError(t, err)

			assert.Equal(t, tt.expectedID, result.ID)
			assert.Equal(t, tt.expectedLogin, result.Login)
		})
	}
}

func TestJWTWithCreateTokenForUser(t *testing.T) {
    // Override config
	config.C.JwtSecret = "test-secret-123"

    // Setup test user
    testUser := schemas.User{
        ID:           456,
        Login:        "directuser",
        PasswordHash: "hashedpassword",
    }
	type claimsResponse struct {
		ID uint `json:"id"`
		Login string `json:"login"`
	}
    // Create a new Fiber app
    app := fiber.New()
    app.Use(JWTMiddleware)
	app.Get("/", func(c *fiber.Ctx) error {
        response := claimsResponse{}
        
        // Safely get ID if present
        if val, ok := c.Locals(IDKey).(uint); ok {
            response.ID = val
        }
        
        // Safely get Login if present
        if val, ok := c.Locals(LoginKey).(string); ok {
            response.Login = val
        }
        
        return c.Status(fiber.StatusOK).JSON(response)
    })

    // Create token using the actual function
    token, err := database.CreateTokenForUser(testUser)
    assert.NoError(t, err)

    t.Run("Valid token", func(t *testing.T) {
        // Create request with valid token
        req := httptest.NewRequest("GET", "/", nil)
        req.Header.Set("Authorization", "Bearer "+token)

        resp, err := app.Test(req)
        assert.NoError(t, err)
        assert.Equal(t, fiber.StatusOK, resp.StatusCode)

        var result claimsResponse
        err = json.NewDecoder(resp.Body).Decode(&result)
        assert.NoError(t, err)

        assert.Equal(t, testUser.ID, result.ID)
        assert.Equal(t, testUser.Login, result.Login)
    })

    t.Run("Invalid token", func(t *testing.T) {
        // Create request with invalid token
        req := httptest.NewRequest("GET", "/", nil)
        req.Header.Set("Authorization", "Bearer invalid.token.here")

        resp, err := app.Test(req)
        assert.NoError(t, err)
        assert.Equal(t, fiber.StatusOK, resp.StatusCode)

        var result claimsResponse
        err = json.NewDecoder(resp.Body).Decode(&result)
        assert.NoError(t, err)

        // Should be zero values since invalid token
        assert.Equal(t, uint(0), result.ID)
        assert.Equal(t, "", result.Login)
    })

    t.Run("Expired token", func(t *testing.T) {
        // Create expired token
        claims := jwt.MapClaims{
            "id":    testUser.ID,
            "login": testUser.Login,
            "exp":   time.Now().Add(-time.Hour).Unix(), // Expired 1 hour ago
        }
        token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
        tokenString, err := token.SignedString([]byte(config.C.JwtSecret))
        assert.NoError(t, err)

        req := httptest.NewRequest("GET", "/", nil)
        req.Header.Set("Authorization", "Bearer "+tokenString)

        resp, err := app.Test(req)
        assert.NoError(t, err)
        assert.Equal(t, fiber.StatusOK, resp.StatusCode)

        var result claimsResponse
        err = json.NewDecoder(resp.Body).Decode(&result)
        assert.NoError(t, err)

        // Should be zero values since token expired
        assert.Equal(t, uint(0), result.ID)
        assert.Equal(t, "", result.Login)
    })

    t.Run("No Authorization header", func(t *testing.T) {
        req := httptest.NewRequest("GET", "/", nil)

        resp, err := app.Test(req)
        assert.NoError(t, err)
        assert.Equal(t, fiber.StatusOK, resp.StatusCode)

        var result claimsResponse
        err = json.NewDecoder(resp.Body).Decode(&result)
        assert.NoError(t, err)

        // Should be zero values since no token provided
        assert.Equal(t, uint(0), result.ID)
        assert.Equal(t, "", result.Login)
    })
}