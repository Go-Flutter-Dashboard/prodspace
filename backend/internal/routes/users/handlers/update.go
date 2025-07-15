package handlers

import (
	"admin/internal/database"
	"admin/internal/database/schemas"
	"admin/internal/models"
	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// UpdateUser
// @Summary Update an existing user by ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Param user body models.UserUpdate true "User update payload"
// @Success 200 {object} models.MessageResponse "Updated Successfully"
// @Failure 400 {object} models.ErrorResponse "Bad Request"
// @Failure 404 {object} models.ErrorResponse "User Not Found"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /users/{id} [patch]
func UpdateUser(c *fiber.Ctx) error {
	id, err := c.ParamsInt("id")
	if err != nil || id < 1 {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "invalid user id",
		})
	}

	input := &models.UserUpdate{}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "invalid request body",
		})
	}

	user := &schemas.User{}
	if err := database.DB.First(&user, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
				Error: "user not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to query user",
		})
	}

	// Update user fields only if they are provided in the input
	if input.Login != nil {
		user.Login = *input.Login
	}

	if input.Name != nil {
		user.Name = *input.Name
	}

	if input.Password != nil {
		hashed := database.Hash(*input.Login, *input.Password)
		user.PasswordHash = hashed
	}

	if err := database.DB.Save(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to update user",
		})
	}

	return c.JSON(user)
}
