package main

import (
	_ "backend/docs"
	"backend/internal/database"
	"backend/internal/middlewares"
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/requestid"
)

// @title ProdSpace API
// @version 1.0
// @description API for ProdSpace application
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and the JWT token
// @termsOfService http://swagger.io/terms/
// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io
// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html
// @host localhost:3000
// @BasePath /
func main() {
	if err := database.InitDatabase(); err != nil {
		panic(err) // failed to connect or migrate
	}

	app := fiber.New()

	// set up middleware
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
		AllowMethods: "GET, POST, PATCH, DELETE",
	}))
	// sets X-Request-ID header with uuids
	app.Use(requestid.New())
	app.Use(middleware.LoggingMiddleware())
	app.Use(middleware.JWTMiddleware)
	CombineRoutes(app)

	log.Fatal(app.Listen(":3000"))
}
