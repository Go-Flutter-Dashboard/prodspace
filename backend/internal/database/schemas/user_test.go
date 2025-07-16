package schemas

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestCreateUserWithWorkspace(t *testing.T) {
	// Setup in-memory SQLite DB for testing
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err, "Failed to open in-memory DB")

	// Auto migrate User and Workspace schemas
	err = db.AutoMigrate(&User{}, &Workspace{})
	assert.NoError(t, err, "Failed to migrate schemas")

	user := &User{
		Login:        "testuser",
		PasswordHash: "hashedpassword",
	}

	err = CreateUserWithWorkspace(db, user)
	assert.NoError(t, err, "CreateUserWithWorkspace should not return error")
	assert.NotZero(t, user.ID, "User ID should be set")
	assert.NotZero(t, user.WorkspaceID, "WorkspaceID should be set")

	// Verify workspace created and linked
	var workspace Workspace
	err = db.First(&workspace, "user_id = ?", user.ID).Error
	assert.NoError(t, err, "Workspace should exist for user")
	assert.Equal(t, user.ID, workspace.UserID, "Workspace UserID should match User ID")
}
