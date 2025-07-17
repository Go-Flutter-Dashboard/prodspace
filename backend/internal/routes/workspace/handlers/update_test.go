package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/models"
	"bytes"
	"encoding/json"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"gorm.io/gorm"
)

func TestAppendMyWorkspaceItem(t *testing.T) {
	database.DB = setupTestDB(t)

	user := &schemas.User{
		Login:        "testuser",
		PasswordHash: "hashedpassword",
	}
	err := schemas.CreateUserWithWorkspace(database.DB, user)
	assert.NoError(t, err)

	app := fiber.New()
	app.Use(mockAuthMiddleware(user.ID))
	app.Post("/workspaces/my/items", AppendMyWorkspaceItem)

	tests := []struct {
		name           string
		payload        models.ItemCreate
		expectedStatus int
	}{
		{
			name: "Create TextItem",
			payload: models.ItemCreate{
				PositionX: 10,
				PositionY: 20,
				ZIndex:    1,
				TextItem: &models.TextItemCreate{
					Content: "Hello",
				},
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Create ImageItem",
			payload: models.ItemCreate{
				PositionX: 15,
				PositionY: 25,
				ZIndex:    2,
				ImageItem: &models.ImageItemCreate{
					Bytes: "imagebytes",
				},
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Create TodoList",
			payload: models.ItemCreate{
				PositionX: 5,
				PositionY: 5,
				ZIndex:    3,
				TodoList: &[]models.TodoItemFieldCreate{
					{
						TextItem: models.TextItemCreate{Content: "Task 1"},
						Done:    false,
					},
				},
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Create ShapeItem",
			payload: models.ItemCreate{
				PositionX: 0,
				PositionY: 0,
				ZIndex:    4,
				ShapeItem: &models.ShapeItemCreate{
					Name: "circle",
				},
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Create DrawingItem",
			payload: models.ItemCreate{
				PositionX: 1,
				PositionY: 1,
				ZIndex:    5,
				DrawingItem: &models.DrawingItemCreate{
					Points: []models.DrawingPointCreate{
						{X: 1, Y: 2},
						{X: 3, Y: 4},
					},
				},
			},
			expectedStatus: fiber.StatusCreated,
		},
		{
			name: "Multiple item types error",
			payload: models.ItemCreate{
				PositionX: 0,
				PositionY: 0,
				ZIndex:    6,
				TextItem: &models.TextItemCreate{
					Content: "text",
				},
				ImageItem: &models.ImageItemCreate{
					Bytes: "bytes",
				},
			},
			expectedStatus: fiber.StatusBadRequest,
		},
		{
			name: "No item type error",
			payload: models.ItemCreate{
				PositionX: 0,
				PositionY: 0,
				ZIndex:    7,
			},
			expectedStatus: fiber.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.payload)
			req := httptest.NewRequest("POST", "/workspaces/my/items", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")

			resp, err := app.Test(req)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedStatus, resp.StatusCode)
		})
	}
}

func TestDeleteMyWorkspaceItem(t *testing.T) {
	database.DB = setupTestDB(t)

	user := &schemas.User{
		Login:        "testuser",
		PasswordHash: "hashedpassword",
	}
	err := schemas.CreateUserWithWorkspace(database.DB, user)
	assert.NoError(t, err)

	// Create an item to delete
	item := schemas.Item{
		WorkspaceID: user.ID,
		PositionX:   10,
		PositionY:   20,
		ZIndex:      1,
		TextItem: &schemas.TextItem{
			Content: "Delete me",
		},
	}
	err = database.DB.Session(&gorm.Session{FullSaveAssociations: true}).Create(&item).Error
	assert.NoError(t, err)

	app := fiber.New()
	app.Use(mockAuthMiddleware(user.ID))
	app.Delete("/workspaces/my/items/:item_id", DeleteMyWorkspaceItem)

	t.Run("Delete existing item", func(t *testing.T) {
		req := httptest.NewRequest("DELETE", "/workspaces/my/items/"+strconv.FormatUint(uint64(item.ID), 10), nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, fiber.StatusOK, resp.StatusCode)
	})

	t.Run("Delete non-existent item", func(t *testing.T) {
		req := httptest.NewRequest("DELETE", "/workspaces/my/items/9999", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, fiber.StatusNotFound, resp.StatusCode)
	})

	t.Run("Invalid item ID", func(t *testing.T) {
		req := httptest.NewRequest("DELETE", "/workspaces/my/items/abc", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, fiber.StatusBadRequest, resp.StatusCode)
	})

	t.Run("Unauthorized", func(t *testing.T) {
		appNoAuth := fiber.New()
		appNoAuth.Delete("/workspaces/my/items/:item_id", DeleteMyWorkspaceItem)
		req := httptest.NewRequest("DELETE", "/workspaces/my/items/1", nil)
		resp, err := appNoAuth.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, fiber.StatusUnauthorized, resp.StatusCode)
	})
}
