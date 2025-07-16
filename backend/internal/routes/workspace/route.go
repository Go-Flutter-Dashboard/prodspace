package workspace

import (
	"backend/internal/routes/workspace/handlers"

	"github.com/gofiber/fiber/v2"
)

func SetupWorkspaceRoutes(app *fiber.App) {
	app.Get("/workspaces/my", handlers.GetMyWorkspace)
	app.Post("/workspaces/my/items", handlers.AppendMyWorkspaceItem)
	app.Delete("/workspaces/my/items/:item_id", handlers.DeleteMyWorkspaceItem)
	app.Get("/workspaces/:user_id", handlers.GetWorkspace)
	app.Post("/workspaces/:user_id/items", handlers.AppendWorkspaceItem)
	app.Delete("/workspaces/:user_id/items/:item_id", handlers.DeleteWorkspaceItem)
}