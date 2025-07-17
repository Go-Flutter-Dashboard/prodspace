package middleware

import (
	"backend/config"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt"
)

type userIDKeyT struct{}

var IDKey userIDKeyT

type userLoginKeyT struct{}

var LoginKey userLoginKeyT

func JWTMiddleware(c *fiber.Ctx) error {
    authHeader := c.Get("Authorization")
    // If no auth header, continue without setting locals
    if authHeader == "" {
        return c.Next()
    }

    tokenString := strings.TrimPrefix(authHeader, "Bearer ")
    if tokenString == "" {
        return c.Next() // Continue without token
    }

    token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
        if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fiber.ErrUnauthorized
        }
        return []byte(config.C.JwtSecret), nil
    })

    // If token is invalid, continue without setting locals
    if err != nil {
        return c.Next()
    }

    if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
        // Check expiration if claim exists
        if exp, ok := claims["exp"].(float64); ok {
            if time.Now().Unix() > int64(exp) {
                return c.Next() // Token expired, continue anyway
            }
        }

        // Set user info if token is valid
        if id, ok := claims["id"].(float64); ok {
            c.Locals(IDKey, uint(id)) // Convert to uint
        }
        if login, ok := claims["login"].(string); ok {
            c.Locals(LoginKey, login)
        }
    }

    return c.Next()
}
