package handlers

import (
	"backend/internal/database"
	"backend/internal/database/schemas"
	"backend/internal/middlewares"
	"backend/internal/models"
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(
		sqlite.Open("file::memory:"), &gorm.Config{
			TranslateError: true,
			Logger:         logger.Default.LogMode(logger.Silent),
		},
	)
	if err != nil {
		t.Fatal("failed to connect test database")
	}

	// Migrate all schemas
	err = db.AutoMigrate(
		&schemas.User{},
		&schemas.Workspace{},
		&schemas.Item{},
		&schemas.TextItem{},
		&schemas.ImageItem{},
		&schemas.TodoListItem{},
		&schemas.TodoListField{},
		&schemas.ShapeItem{},
		&schemas.DrawingItem{},
		&schemas.Point{},
	)
	if err != nil {
		t.Fatal("failed to migrate test database")
	}

	return db
}

// mockAuthMiddleware creates a middleware that sets the user ID from a header
func mockAuthMiddleware(userID uint) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// For testing, we'll just set the user ID from a header
		c.Locals(middleware.IDKey, userID)
		return c.Next()
	}
}

func TestGetMyWorkspace(t *testing.T) {
	// Setup test database
	
	database.DB = setupTestDB(t)
	
	// Create test data
	user := &schemas.User{
		Login:        "testuser",
		PasswordHash: "hashedpassword",
	}
	
	err := schemas.CreateUserWithWorkspace(database.DB, user)

	assert.NoError(t, err, "Failed to create user and workspace")

	// Create test items with all types
	items := []schemas.Item{
		{
			WorkspaceID: user.ID,
			PositionX:   10,
			PositionY:   999,
			ZIndex:      1,
			TextItem: &schemas.TextItem{
				Content: "Test content",
			},
		},
		{
			WorkspaceID: user.ID,
			PositionX:   30,
			PositionY:   40,
			ZIndex:      2,
			ImageItem: &schemas.ImageItem{
				Bytes: "test-image-bytes",
			},
		},
		{
			WorkspaceID: user.ID,
			PositionX:   50,
			PositionY:   60,
			ZIndex:      3,
			ListItem: &schemas.TodoListItem{
				TodoListFields: []schemas.TodoListField{
					{
						TextItem: &schemas.TextItem{
							Content: "Task 1",
						},
						Done: false,
					},
				},
			},
		},
		{
			WorkspaceID: user.ID,
			PositionX:   70,
			PositionY:   80,
			ZIndex:      4,
			ShapeItem: &schemas.ShapeItem{
				Name: "circle",
			},
		},
		{
			WorkspaceID: user.ID,
			PositionX:   90,
			PositionY:   100,
			ZIndex:      5,
			DrawingItem: &schemas.DrawingItem{
				Points: []schemas.Point{
					{X: 1, Y: 2},
					{X: 3, Y: 4},
				},
			},
		},
	}
	
	
	w := &schemas.Workspace{}
	err = database.DB.First(w, "user_id = ?", user.ID).Error
	if err != nil {
	    t.Fatal("failed to load workspace")
	}

	for i := range items {
	    items[i].WorkspaceID = w.UserID
	    err = database.DB.Session(&gorm.Session{FullSaveAssociations: true}).Create(&items[i]).Error
	    if err != nil {
	        t.Fatalf("failed to save item %d: %v", i, err)
	    }
	}


	tests := []struct {
		name           string
		userID         uint
		expectedStatus int
		expectedItems  int
	}{
		{
			name:           "Unauthorized - missing user ID",
			userID:         0, // 0 means no middleware will set the user ID
			expectedStatus: fiber.StatusUnauthorized,
		},
		{
			name:           "Invalid user ID",
			userID:         10,
			expectedStatus: fiber.StatusNotFound,
		},
		{
			name:           "Workspace not found",
			userID:         999, // Non-existent user ID
			expectedStatus: fiber.StatusNotFound,
		},
		{
			name:           "Successful workspace retreival",
			userID:         1, // Existing user ID
			expectedStatus: fiber.StatusOK,
			expectedItems:  5,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			app := fiber.New()

			// Only add auth middleware if we're testing with a user ID
			if tt.userID != 0 {
				app.Use(mockAuthMiddleware(tt.userID))
			}

			app.Get("/workspaces/my", GetMyWorkspace)

			req := httptest.NewRequest("GET", "/workspaces/my", nil)
			resp, err := app.Test(req)
			assert.NoError(t, err)
			assert.Equal(t, tt.expectedStatus, resp.StatusCode)

			if tt.expectedStatus == fiber.StatusOK {
				var response models.WorkspaceRead
				err := json.NewDecoder(resp.Body).Decode(&response)
				fmt.Printf("%+v\n", response)
				assert.NoError(t, err)
				assert.Equal(t, tt.expectedItems, len(response.Items))

				// Verify all item types were properly loaded
				for _, item := range response.Items {
					switch {
					case item.TextItem != nil:
						assert.Equal(t, "Test content", item.TextItem.Content)
					case item.ImageItem != nil:
						assert.Equal(t, "test-image-bytes", item.ImageItem.Bytes)
					case item.TodoListItem != nil:
						assert.Equal(t, 1, len(item.TodoListItem))
						assert.Equal(t, "Task 1", item.TodoListItem[0].TextItemRead.Content)
					case item.ShapeItem != nil:
						assert.Equal(t, "circle", item.ShapeItem.Name)
					case item.DrawingItem != nil:
						assert.Equal(t, 2, len(item.DrawingItem.Points))
						assert.Equal(t, float64(1), item.DrawingItem.Points[0].X)
					}
				}
			}
		})
	}
}