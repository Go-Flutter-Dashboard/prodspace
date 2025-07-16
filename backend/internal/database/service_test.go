package database

import (
	"testing"
	"time"

	"backend/config"
	"backend/internal/database/schemas"

	"github.com/dgrijalva/jwt-go"
	"github.com/stretchr/testify/assert"
)

func TestHashAndVerifyPassword(t *testing.T) {
	login := "testuser"
	password := "testpassword"

	hashed := Hash(login, password)
	assert.NotEmpty(t, hashed, "Hash should not be empty")

	// Verify correct password
	ok := VerifyPassword(hashed, login, password)
	assert.True(t, ok, "Password verification should succeed for correct password")

	// Verify incorrect password
	ok = VerifyPassword(hashed, login, "wrongpassword")
	assert.False(t, ok, "Password verification should fail for incorrect password")
}

func TestCreateTokenForUser(t *testing.T) {
	// Remove usage of jwtSecret variable if any, since it was removed from service.go
	user := schemas.User{
		ID:    1,
		Login: "testuser",
	}

	token, err := CreateTokenForUser(user)
	assert.NoError(t, err, "Token creation should not error")
	assert.NotEmpty(t, token, "Token should not be empty")

	// Optionally, parse token to verify claims
	parsedToken, err := jwt.Parse(token, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.C.JwtSecret), nil
	})
	assert.NoError(t, err, "Token parsing should not error")
	if claims, ok := parsedToken.Claims.(jwt.MapClaims); ok && parsedToken.Valid {
		assert.Equal(t, float64(user.ID), claims["id"], "Token claim id should match user ID")
		assert.Equal(t, user.Login, claims["login"], "Token claim login should match user login")
		assert.Equal(t, "user", claims["role"], "Token claim role should be 'user'")
		exp, ok := claims["exp"].(float64)
		assert.True(t, ok, "Token claim exp should be a float64")
		assert.True(t, int64(exp) > time.Now().Unix(), "Token expiration should be in the future")
	} else {
		t.Error("Token claims invalid")
	}
}
