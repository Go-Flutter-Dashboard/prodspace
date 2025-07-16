package handlers

import (
	"backend/config"
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/models"
	"errors"
	"time"

	"github.com/dgrijalva/jwt-go"
	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// @Summary Register a new user
// @Tags auth
// @Accept json
// @Produce json
// @Param user body models.UserCreate true "User create payload"
// @Success 200 {object} models.CreatedResponse
// @Failure 400 {object} models.ErrorResponse "Bad Request"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /register [post]
func RegisterUser(c *fiber.Ctx) error {
    // Parse request
    userCreate := new(models.UserCreate)
    if err := c.BodyParser(userCreate); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid request body",
        })
    }

    // Validate input
    if userCreate.Login == "" || userCreate.Password == "" {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "login and password are required",
        })
    }

    // Create user
    user := &schemas.User{
        Login:        userCreate.Login,
        PasswordHash: database.Hash(userCreate.Login, userCreate.Password),
    }

    // Create user with workspace
    if err := schemas.CreateUserWithWorkspace(database.DB, user); err != nil {
        if errors.Is(err, gorm.ErrDuplicatedKey) {
            return c.Status(fiber.StatusConflict).JSON(models.ErrorResponse{
                Error: "username already exists",
            })
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to create user account",
        })
    }

    // Generate JWT token
    token, err := generateJWTToken(user)
    if err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to generate authentication token",
        })
    }

    // Return response with token
    return c.Status(fiber.StatusCreated).JSON(models.AuthResponse{
        Message: "registration successful",
        Token:   token,
        UserID:  user.ID,
    })
}

// Helper function to generate JWT token
func generateJWTToken(user *schemas.User) (string, error) {
    // Set token claims
    claims := jwt.MapClaims{
        "id":    user.ID,
        "login": user.Login,
        "exp":   time.Now().Add(time.Hour * 24).Unix(), // 24 hour expiration
    }

    // Create token
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

    // Generate encoded token
    return token.SignedString([]byte(config.C.JwtSecret))
}