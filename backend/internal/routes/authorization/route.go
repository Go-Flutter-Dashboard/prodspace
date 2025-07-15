package authorization

import (
	"admin/internal/routes/authorization/handlers"

	"github.com/gofiber/fiber/v2"
)

func SetupAuthRoutes(app *fiber.App) {
	app.Post("/auth", handlers.Login)
}
