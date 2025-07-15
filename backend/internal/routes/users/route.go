package users

import (
	"admin/internal/routes/users/handlers"

	"github.com/gofiber/fiber/v2"
)

func SetUpUserRoutes(app *fiber.App) {
	app.Post("/users/", handlers.CreateUser)
	app.Get("/users/", handlers.GetUsersPaginate)
	app.Get("/users/count", handlers.GetUserCount)
	app.Get("/users/:id", handlers.GetUser)
	app.Patch("/users/:id", handlers.UpdateUser)
	app.Delete("/users/:id", handlers.DeleteUser)
}
