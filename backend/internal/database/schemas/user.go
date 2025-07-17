package schemas

import "gorm.io/gorm"

type User struct {
	ID           uint   `gorm:"primaryKey"`
	Login        string `gorm:"uniqueIndex;not null"`
	PasswordHash string `gorm:"not null" json:"-"`
	WorkspaceID  uint
}

// Create a workspace for the user
func CreateUserWithWorkspace(db *gorm.DB, user *User) error {
    return db.Transaction(func(tx *gorm.DB) error {
        // 1. First create the user (without workspace reference)
        if err := tx.Omit("Workspace").Create(user).Error; err != nil {
            return err
        }

        // 2. Create the workspace
        workspace := Workspace{
            UserID: user.ID,
        }
        if err := tx.Create(&workspace).Error; err != nil {
            return err
        }

        // 3. Update user with workspace reference
        user.WorkspaceID = user.ID// Since workspace.UserID = user.ID
        return tx.Model(user).Update("WorkspaceID", user.WorkspaceID).Error
    })
}