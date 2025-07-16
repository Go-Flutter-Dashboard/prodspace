package users

import (
	"backend/internal/routes/users/handlers"

	"github.com/gofiber/fiber/v2"
)

func SetupUserRoutes(app *fiber.App) {
	app.Post("/register/", handlers.RegisterUser)
	app.Post("/login/", handlers.LoginUser)
	app.Get("/users/", handlers.GetUsersPaginate)
	app.Get("/users/count", handlers.GetUserCount)
	app.Get("/users/:id", handlers.GetUser)
	app.Patch("/users/:id", handlers.UpdateUser)
	app.Delete("/users/:id", handlers.DeleteUser)
}
