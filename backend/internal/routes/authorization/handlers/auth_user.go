package handlers

import (
	"admin/internal/database"
	"admin/internal/database/schemas"
	"admin/internal/models"
	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// Login godoc
// @Summary User Login
// @Description Authenticate a user with login and password, returning a token
// @Tags auth
// @Accept json
// @Produce json
// @Param authInput body models.AuthInput true "Login and Password"
// @Success 200 {object} map[string]string "User logged in successfully"
// @Failure 400 {object} models.ErrorResponse "Invalid request body or missing fields"
// @Failure 404 {object} models.ErrorResponse "User not found"
// @Failure 401 {object} models.ErrorResponse "Incorrect password"
// @Failure 500 {object} models.ErrorResponse "Failed to query database or create token"
// @Router /auth [post]
func Login(c *fiber.Ctx) error {
	data := &models.AuthInput{}

	if err := c.BodyParser(data); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "invalid request body",
		})
	}

	if data.Login == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "field login cannot be empty",
		})
	}

	if data.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "field password cannot be empty",
		})
	}

	var user schemas.User
	if err := database.DB.Where("login = ?", data.Login).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
				Error: "user not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to query database",
		})
	}

	hash := database.Hash(data.Login, data.Password)

	if user.PasswordHash != hash {
		return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
			Error: "incorrect password",
		})
	}

	token, err := database.CreateTokenForUser(user)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to create token",
		})
	}

	c.Set("Authorization", "Bearer "+token)

	return c.Status(fiber.StatusOK).JSON(models.MessageResponse{
		Message: "logged in successfully",
	})
}
