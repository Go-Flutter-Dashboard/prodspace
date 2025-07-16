package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/models"

	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// @Summary Get a user by ID
// @Description Retrieve a user by their unique ID
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "User ID"
// @Success 200 {object} models.UserRead
// @Failure 400 {object} map[string]string "Bad Request"
// @Failure 404 {object} map[string]string "User Not Found"
// @Failure 500 {object} map[string]string "Internal Server Error"
// @Router /users/{id} [get]
func GetUser(c *fiber.Ctx) error {
	id, err := c.ParamsInt("id")

	if err != nil || id < 0 {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "'id' parameter is malformed; should be > 0",
		})
	}

	user := &schemas.User{}

	if err := database.DB.First(user, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
				Error: "user not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to retrieve user",
		})
	}

	userRead := models.UserRead{
		ID:    user.ID,
		Login: user.Login,
	}

	return c.Status(fiber.StatusOK).JSON(userRead)
}

type userQueryParams struct {
	Page               int    `query:"page"`
	Limit              int    `query:"limit"`
	UserStatus         string `query:"user_status"`
	SubscriptionPlan   string `query:"subscription_plan"`
	SubscriptionStatus string `query:"subscription_status"`
}

// GetUserPaginate
// @Summary Get paginated list of users
// @Description Retrieve a paginated list of users with optional page and limit query parameters
// @Tags users
// @Accept json
// @Produce json
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of users per page" default(10)
// @Success 200 {object} []models.UserRead
// @Failure 400 {object} models.ErrorResponse "Malformed query parameters"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /users [get]
func GetUsersPaginate(c *fiber.Ctx) error {
	params := &userQueryParams{}

	if err := c.QueryParser(params); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "malformed query parameters",
		})
	}

	offset := (params.Page - 1) * params.Limit

	var users []schemas.User

	err :=
		database.DB.
			Limit(params.Limit).
			Offset(offset).
			Find(&users).
			Error

	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "failed to find users",
		})
	}

	userReads := make([]models.UserRead, len(users))
	for i, user := range users {
		userReads[i] = models.UserRead{
			ID:          user.ID,
			Login:       user.Login,
			WorkspaceID: user.WorkspaceID,
		}
	}

	return c.Status(fiber.StatusOK).JSON(userReads)
}

// GetUserCount
// @Summary Get the total number of users
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} models.CountResponse "User count object"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /users/count [get]
func GetUserCount(c *fiber.Ctx) error {
	var count int64

	if err := database.DB.Model(&schemas.User{}).Count(&count).Error; err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "failed to count users",
		})
	}

	return c.Status(fiber.StatusOK).JSON(models.CountResponse{
		Count: count,
	})
}

// @Summary Authenticate user
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body models.UserCreate true "Login credentials"
// @Success 200 {object} models.AuthResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /login [post]
func LoginUser(c *fiber.Ctx) error {
    // Parse request
    loginReq := new(models.UserCreate)
    if err := c.BodyParser(loginReq); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid request format",
        })
    }

    // Validate input
    if loginReq.Login == "" || loginReq.Password == "" {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "login and password are required",
        })
    }

    // Find user by login
    var user schemas.User
    if err := database.DB.Where("login = ?", loginReq.Login).First(&user).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
                Error: "invalid credentials", // Generic message for security
            })
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to authenticate user",
        })
    }

    // Verify password
    if !database.VerifyPassword(user.PasswordHash, loginReq.Login, loginReq.Password) {
        return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
            Error: "invalid credentials",
        })
    }

    // Generate JWT token
    token, err := generateJWTToken(&user)
    if err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to generate authentication token",
        })
    }

    // Return successful response
    return c.JSON(models.AuthResponse{
        Message: "login successful",
        Token:   token,
        UserID:  user.ID,
    })
}