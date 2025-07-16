package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/models"
	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

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

	userUpdate := &models.UserUpdate{}
	if err := c.BodyParser(&userUpdate); err != nil {
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
	
	if userUpdate.OldPassword == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "old password required to update the user",
		})
	}
	
	if userUpdate.Login == "" {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "login required",
		})
	}
	
	inputHash := database.Hash(userUpdate.Login, userUpdate.OldPassword)
	if user.PasswordHash != inputHash {
		return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
			Error: "invalid login or old password",
		})
	}
	
	user.Login = userUpdate.Login
	
	if userUpdate.NewPassword != nil {
		user.PasswordHash = database.Hash(user.Login, *userUpdate.NewPassword)
	}

	if err := database.DB.Save(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to update user",
		})
	}

	return c.JSON(user)
}
