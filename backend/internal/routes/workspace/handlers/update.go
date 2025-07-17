package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	middleware "backend/internal/middlewares"
	"backend/internal/models"
	"errors"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// @Summary Append a workspace item
// @Tags workspaces
// @Accept json
// @Produce json
// @Param item body models.ItemCreate true "Item to create"
// @Param user_id path int true "User ID"
// @Success 201 {object} models.CreatedResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /workspaces/{user_id}/items [post]
func AppendWorkspaceItem(c *fiber.Ctx) error {
    // Validate user_id
    userID, err := c.ParamsInt("user_id")
    if err != nil || userID < 1 {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid user ID",
        })
    }

    // Parse request
    var itemCreate models.ItemCreate
    if err := c.BodyParser(&itemCreate); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid request body",
        })
    }

	// Validate exactly one item type is provided
	itemTypes := 0
	if itemCreate.TextItem != nil { itemTypes++ }
	if itemCreate.ImageItem != nil { itemTypes++ }
	if itemCreate.TodoList != nil { itemTypes++ }
	if itemCreate.ShapeItem != nil { itemTypes++ }
	if itemCreate.DrawingItem != nil { itemTypes++ }
	
	if itemTypes != 1 {
		return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
			Error: "must provide exactly one item type (text, image, todo list, shape, or drawing)",
		})
	}

	// Create base item
	item := schemas.Item{
		WorkspaceID: uint(userID),
		PositionX:   itemCreate.PositionX,
		PositionY:   itemCreate.PositionY,
		ZIndex:      itemCreate.ZIndex,
		Color:       itemCreate.Color,
		Scale:       itemCreate.Scale,
	}

	// Handle different item types except ShapeItem
	switch {
	case itemCreate.TextItem != nil:
		
		if itemCreate.TextItem.Content == "" {
			return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
				Error: "cannot create am empty text item",
			})
		}
		
		item.TextItem = &schemas.TextItem{
			Content: itemCreate.TextItem.Content,
		}
		
	case itemCreate.ImageItem != nil:
		item.ImageItem = &schemas.ImageItem{
			Bytes: itemCreate.ImageItem.Bytes,
		}
		
	case itemCreate.TodoList != nil:
		var fields []schemas.TodoListField
		for _, f := range *itemCreate.TodoList {
			fields = append(fields, schemas.TodoListField{
				Done: f.Done,
				TextItem: &schemas.TextItem{
					Content: f.TextItem.Content,
				},
			})
		}
		item.ListItem = &schemas.TodoListItem{
			TodoListFields: fields,
		}
	case itemCreate.ShapeItem != nil:
		item.ShapeItem = &schemas.ShapeItem{
			Name:        itemCreate.ShapeItem.Name,
		}
	case itemCreate.DrawingItem != nil:
		points := make([]schemas.Point, 0, len(itemCreate.DrawingItem.Points))
		for _, p := range itemCreate.DrawingItem.Points {
			points = append(points, schemas.Point{
				X: p.X,
				Y: p.Y,
			})
		}
		item.DrawingItem = &schemas.DrawingItem{
			Points: points,
		}
	}

    // Find workspace
    var workspace schemas.Workspace
    if err := database.DB.
        Preload("Items").
        First(&workspace, "user_id = ?", userID).
        Error; err != nil {
        
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
                Error: "workspace not found",
            })
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to find workspace",
        })
    }

    // Create item
    if err := database.DB.Create(&item).Error; err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to create item",
        })
    }

    // Associate with workspace
    if err := database.DB.Model(&workspace).Association("Items").Append(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to associate item with workspace",
        })
    }

    return c.Status(fiber.StatusCreated).JSON(models.CreatedResponse{
        Message: "item created successfully",
        ID:      item.ID,
    })
}

// @Summary Delete a workspace item by item ID and user ID
// @Tags workspaces
// @Accept json
// @Produce json
// @Param user_id path int true "User ID"
// @Param item_id path int true "Item ID"
// @Success 200 {object} models.MessageResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /workspaces/{user_id}/items/{item_id} [delete]
func DeleteWorkspaceItem(c *fiber.Ctx) error {
    // Validate parameters
    userID, err := c.ParamsInt("user_id")
    if err != nil || userID < 1 {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid user id",
        })
    }

    itemID, err := c.ParamsInt("item_id")
    if err != nil || itemID < 1 {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid item id", 
        })
    }

    // Execute in transaction
    err = database.DB.Transaction(func(tx *gorm.DB) error {
        // Verify workspace exists
        var workspace schemas.Workspace
        if err := tx.Select("user_id").First(&workspace, "user_id = ?", userID).Error; err != nil {
            if errors.Is(err, gorm.ErrRecordNotFound) {
                return fiber.NewError(fiber.StatusNotFound, "workspace not found")
            }
            return err
        }

        // Delete item with workspace verification
        result := tx.Where("id = ? AND workspace_id = ?", itemID, userID).Delete(&schemas.Item{})
        if result.Error != nil {
            return result.Error
        }
        
        if result.RowsAffected == 0 {
            return fiber.NewError(fiber.StatusNotFound, "item not found in workspace")
        }

        return nil
    })

    // Handle transaction errors
    if err != nil {
        if e, ok := err.(*fiber.Error); ok {
            return c.Status(e.Code).JSON(models.ErrorResponse{Error: e.Message})
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to delete item",
        })
    }

    return c.Status(fiber.StatusOK).JSON(models.MessageResponse{
        Message: "item deleted successfully",
    })
}

// @Summary Append a workspace item
// @Tags workspaces
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param item body models.ItemCreate true "Item to create"
// @Success 201 {object} models.CreatedResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /workspaces/my/items [post]
func AppendMyWorkspaceItem(c *fiber.Ctx) error {
    userID, ok := c.Locals(middleware.IDKey).(uint)
	
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
			Error: "unauthorized",
		})
	}

    // Parse request
    var itemCreate models.ItemCreate
    if err := c.BodyParser(&itemCreate); err != nil {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid request body",
        })
    }

    // Validate exactly one item type is provided
    itemTypes := 0
    if itemCreate.TextItem != nil { itemTypes++ }
    if itemCreate.ImageItem != nil { itemTypes++ }
    if itemCreate.TodoList != nil { itemTypes++ }
    if itemCreate.ShapeItem != nil { itemTypes++ }
    if itemCreate.DrawingItem != nil { itemTypes++ }
    
    if itemTypes != 1 {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "must provide exactly one item type (text, image, or todo list)",
        })
    }

    // Create base item
    item := schemas.Item{
        WorkspaceID: uint(userID),
        PositionX:   itemCreate.PositionX,
        PositionY:   itemCreate.PositionY,
        ZIndex:      itemCreate.ZIndex,
        Color:       itemCreate.Color,
        Scale:       itemCreate.Scale,
        Width:       itemCreate.Width,
        Height:      itemCreate.Height,
    }

    // Handle different item types except ShapeItem
    switch {
    case itemCreate.TextItem != nil:
		
		if itemCreate.TextItem.Content == "" {
			return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
				Error: "cannot create am empty text item",
			})
		}
		
        item.TextItem = &schemas.TextItem{
            Content: itemCreate.TextItem.Content,
        }
        
    case itemCreate.ImageItem != nil:
        item.ImageItem = &schemas.ImageItem{
            Bytes: itemCreate.ImageItem.Bytes,
        }
        
    case itemCreate.TodoList != nil:
        var fields []schemas.TodoListField
        for _, f := range *itemCreate.TodoList {
            fields = append(fields, schemas.TodoListField{
                Done: f.Done,
                TextItem: &schemas.TextItem{
                    Content: f.TextItem.Content,
                },
            })
        }
        item.ListItem = &schemas.TodoListItem{
            TodoListFields: fields,
        }
    case itemCreate.ShapeItem != nil:
        item.ShapeItem = &schemas.ShapeItem{
            Name:        itemCreate.ShapeItem.Name,
        }
    case itemCreate.DrawingItem != nil:
        var points []schemas.Point
        for _, p := range itemCreate.DrawingItem.Points {
            points = append(points, schemas.Point{
                X: p.X,
                Y: p.Y,
            })
        }
        item.DrawingItem = &schemas.DrawingItem{
            Points: points,
        }
    }

    // Find workspace
    var workspace schemas.Workspace
    if err := database.DB.
        Preload("Items").
        First(&workspace, "user_id = ?", userID).
        Error; err != nil {
        
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return c.Status(fiber.StatusNotFound).JSON(models.ErrorResponse{
                Error: "workspace not found",
            })
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to find workspace",
        })
    }

    // Create item
    if err := database.DB.Create(&item).Error; err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to create item",
        })
    }

    // Associate with workspace
    if err := database.DB.Model(&workspace).Association("Items").Append(&item); err != nil {
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to associate item with workspace",
        })
    }

    return c.Status(fiber.StatusCreated).JSON(models.CreatedResponse{
        Message: "item created successfully",
        ID:      item.ID,
    })
}

// @Summary Delete a workspace item by item ID and user ID
// @Tags workspaces
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param item_id path int true "Item ID"
// @Success 200 {object} models.MessageResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /workspaces/my/items/{item_id} [delete]
func DeleteMyWorkspaceItem(c *fiber.Ctx) error {
    userID, ok := c.Locals(middleware.IDKey).(uint)
	
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(models.ErrorResponse{
			Error: "unauthorized",
		})
	}

    itemID, err := c.ParamsInt("item_id")
    if err != nil || itemID < 1 {
        return c.Status(fiber.StatusBadRequest).JSON(models.ErrorResponse{
            Error: "invalid item id", 
        })
    }

    // Execute in transaction
    err = database.DB.Transaction(func(tx *gorm.DB) error {
        // Verify workspace exists
        var workspace schemas.Workspace
        if err := tx.Select("user_id").First(&workspace, "user_id = ?", userID).Error; err != nil {
            if errors.Is(err, gorm.ErrRecordNotFound) {
                return fiber.NewError(fiber.StatusNotFound, "workspace not found")
            }
            return err
        }

        // Delete item with workspace verification
        result := tx.Where("id = ? AND workspace_id = ?", itemID, userID).Delete(&schemas.Item{})
        if result.Error != nil {
            return result.Error
        }
        
        if result.RowsAffected == 0 {
            return fiber.NewError(fiber.StatusNotFound, "item not found in workspace")
        }

        return nil
    })

    // Handle transaction errors
    if err != nil {
        if e, ok := err.(*fiber.Error); ok {
            return c.Status(e.Code).JSON(models.ErrorResponse{Error: e.Message})
        }
        return c.Status(fiber.StatusInternalServerError).JSON(models.ErrorResponse{
            Error: "failed to delete item",
        })
    }

    return c.Status(fiber.StatusOK).JSON(models.MessageResponse{
        Message: "item deleted successfully",
    })
}