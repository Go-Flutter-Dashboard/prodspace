package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	middleware "backend/internal/middlewares"
	"backend/internal/models"
	"errors"
	"fmt"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// @Summary Get workspace by user id
// @Description Retrieve a workspace by their unique user id
// @Tags workspaces
// @Accept json
// @Produce json
// @Param user_id path int true "User id"
// @Success 200 {object} models.WorkspaceRead
// @Failure 400 {object} models.ErrorResponse "Bad Request"
// @Failure 404 {object} models.ErrorResponse "User Not Found"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /workspaces/{user_id} [get]
func GetWorkspace(c *fiber.Ctx) error {
	id, err := c.ParamsInt("user_id")
	if err != nil || id < 1 {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "invalid user ID",
		})
	}

	// Load workspace with all nested relationships
	var workspace schemas.Workspace
	err = database.DB.
		Preload("Items.TextItem").
		Preload("Items.ImageItem").
		Preload("Items.ListItem.TodoListFields.TextItem").
		Preload("Items.ShapeItem").
		Preload("Items.DrawingItem").
		Joins("User").
		First(&workspace, "user_id = ?", id).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
				Error: "workspace not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to get workspace",
		})
	}

	// Convert to response model
	itemReads := make([]models.ItemRead, 0, len(workspace.Items))
	for _, item := range workspace.Items {
		itemRead := models.ItemRead{
			ID:          item.ID,
			PositionX:   item.PositionX,
			PositionY:   item.PositionY,
			ZIndex:      item.ZIndex,
			WorkspaceID: item.WorkspaceID,
			Color:       item.Color,
			Scale:       item.Scale,
		}

		// Handle text items
		if item.TextItem != nil {
			itemRead.TextItem = &models.TextItemRead{
				Content: item.TextItem.Content,
			}
		}

		// Handle image items
		if item.ImageItem != nil {
			itemRead.ImageItem = &models.ImageItemRead{
				Bytes: item.ImageItem.Bytes,
			}
		}

		// Handle list items
		if item.ListItem != nil {
			listFields := make([]models.TodoListItemFieldRead, 0, len(item.ListItem.TodoListFields))
			for _, field := range item.ListItem.TodoListFields {
				if field.TextItem != nil {
					listFields = append(listFields, models.TodoListItemFieldRead{
						TextItemRead: models.TextItemRead{
							Content: field.TextItem.Content,
						},
						Done: field.Done,
					})
				}
			}
			itemRead.TodoListItem = listFields
		}

		// Handle shape items
		if item.ShapeItem != nil {
			itemRead.ShapeItem = &models.ShapeItemRead{
				Name: item.ShapeItem.Name,
			}
		}

		// Handle drawing items
		if item.DrawingItem != nil {
			points := make([]models.DrawingPointRead, 0, len(item.DrawingItem.Points))
			for _, p := range item.DrawingItem.Points {
				points = append(points, models.DrawingPointRead{
					X: p.X,
					Y: p.Y,
				})
			}
			itemRead.DrawingItem = &models.DrawingItemRead{
				Points: points,
			}
		}

		itemReads = append(itemReads, itemRead)
	}

	return c.Status(fiber.StatusOK).JSON(models.WorkspaceRead{
		Items: itemReads,
	})
}

// @Summary Get a user's workspace
// @Tags workspaces
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.WorkspaceRead
// @Failure 400 {object} models.ErrorResponse "Bad Request"
// @Failure 401 {object} models.ErrorResponse "Bad Request"
// @Failure 404 {object} models.ErrorResponse "User Not Found"
// @Failure 500 {object} models.ErrorResponse "Internal Server Error"
// @Router /workspaces/my [get]
func GetMyWorkspace(c *fiber.Ctx) error {
	id, ok := c.Locals(middleware.IDKey).(uint)

	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
			Error: "unauthorized",
		})
	}

	if id < 1 {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "invalid user ID",
		})
	}

	// Load workspace with all nested relationships
	var workspace schemas.Workspace
	err := database.DB.
		Preload("Items.TextItem").
		Preload("Items.ImageItem").
		Preload("Items.ListItem.TodoListFields.TextItem").
		Preload("Items.ShapeItem").
		Preload("Items.DrawingItem.Points").
		Where("user_id = ?", id).
		First(&workspace, "user_id = ?", id).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
				Error: "workspace not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
			Error: "failed to get workspace (gorm err)",
		})
	}

	// Convert to response model
	itemReads := make([]models.ItemRead, 0, len(workspace.Items))
	for _, item := range workspace.Items {
		itemRead := models.ItemRead{
			ID:          item.ID,
			PositionX:   item.PositionX,
			PositionY:   item.PositionY,
			ZIndex:      item.ZIndex,
			WorkspaceID: item.WorkspaceID,
		}

		// Handle text items
		if item.TextItem != nil {
			itemRead.TextItem = &models.TextItemRead{
				Content: item.TextItem.Content,
			}
		}

		// Handle image items
		if item.ImageItem != nil {
			itemRead.ImageItem = &models.ImageItemRead{
				Bytes: item.ImageItem.Bytes,
			}
		}

		// Handle list items
		if item.ListItem != nil {
			listFields := make([]models.TodoListItemFieldRead, 0, len(item.ListItem.TodoListFields))
			for _, field := range item.ListItem.TodoListFields {
				if field.TextItem != nil {
					listFields = append(listFields, models.TodoListItemFieldRead{
						TextItemRead: models.TextItemRead{
							Content: field.TextItem.Content,
						},
						Done: field.Done,
					})
				}
			}
			itemRead.TodoListItem = listFields
		}

		// Handle shape items
		if item.ShapeItem != nil {
			itemRead.ShapeItem = &models.ShapeItemRead{
				Name: item.ShapeItem.Name,
			}
		}
		
		if item.DrawingItem != nil {
			var pointReads []models.DrawingPointRead
			for _, point := range item.DrawingItem.Points {
				pointRead := models.DrawingPointRead{
					X: point.X,
					Y: point.Y,
				}
				pointReads = append(pointReads, pointRead)
			}
			itemRead.DrawingItem.Points = pointReads
		}
		
		itemReads = append(itemReads, itemRead)
	}
	fmt.Println("Item reads: ", itemReads)
	return c.Status(fiber.StatusOK).JSON(models.WorkspaceRead{
		Items: itemReads,
	})
}
