package handlers

import (
	"admin/internal/database"
	"admin/internal/database/schemas"
	"admin/internal/models"
	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// CreateUser
// @Summary Create a new user
// @Tags users
// @Accept json
// @Produce json
// @Param user body models.UserCreate true "User create payload"
// @Success 200 {object} models.CreatedResponse
// @Failure 400 {object} models.ErrorResponse "Bad Request"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /users [post]
func CreateUser(c *fiber.Ctx) error {
	userCreate := &models.UserCreate{}

	if err := c.BodyParser(userCreate); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: err.Error(),
		})
	}

	user := &schemas.User{
		Login:        userCreate.Login,
		Name:         userCreate.Name,
		PasswordHash: database.Hash(userCreate.Login, userCreate.Password),
	}

	if err := database.DB.Create(user).Error; err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
				Error: "user with this login already exists",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to create user",
		})
	}

	return c.Status(fiber.StatusOK).JSON(models.CreatedResponse{
		Message: "user created successfully",
		ID:      user.ID,
	})
}
