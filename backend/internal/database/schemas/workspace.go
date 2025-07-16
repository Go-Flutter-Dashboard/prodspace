package schemas

import "gorm.io/gorm"

type Workspace struct {
	UserID uint `gorm:"primaryKey;autoIncrement:false"`
	User   *User
	Items  []Item `gorm:"foreignKey:WorkspaceID"`
}

type Item struct {
	ID          uint          `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID uint          `gorm:"primaryKey;autoIncrement:false"` // Part of composite PK
	PositionX   float64       `gorm:"not null"`
	PositionY   float64       `gorm:"not null"`
	ZIndex      uint          `gorm:"not null"`
	Width       float64       `gorm:"not null"`
	Height      float64       `gorm:"not null"`
	Color       string        `gorm:"not null;default:'#FFFFFF'"`
	Scale       float64       `gorm:"not null;default:1.0"`
	TextItem    *TextItem     `gorm:"foreignKey:ItemID,WorkspaceID;references:ID,WorkspaceID"`
	ImageItem   *ImageItem    `gorm:"foreignKey:ItemID,WorkspaceID;references:ID,WorkspaceID"`
	ListItem    *TodoListItem `gorm:"foreignKey:ItemID,WorkspaceID;references:ID,WorkspaceID"`
	ShapeItem   *ShapeItem    `gorm:"foreignKey:ItemID,WorkspaceID;references:ID,WorkspaceID"`
	DrawingItem *DrawingItem  `gorm:"foreignKey:ItemID,WorkspaceID;references:ID,WorkspaceID"`
}

type ShapeItem struct {
	ItemID      uint   `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID uint   `gorm:"primaryKey;autoIncrement:false"`
	Name        string `gorm:"not null"`
}

type TextItem struct {
	ItemID      uint   `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID uint   `gorm:"primaryKey;autoIncrement:false"`
	Content     string `gorm:"not null"`
}

type ImageItem struct {
	ItemID      uint   `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID uint   `gorm:"primaryKey;autoIncrement:false"`
	Bytes       string `gorm:"not null"`
}

type TodoListField struct {
	ID             uint `gorm:"primaryKey;autoIncrement:false"`
	TodoListItemID uint `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID    uint `gorm:"primaryKey;autoIncrement:false"`
	TextItemID     uint
	TextItem       *TextItem `gorm:"foreignKey:TextItemID,WorkspaceID;references:ItemID,WorkspaceID"`
	Done           bool      `gorm:"not null"`
}

type TodoListItem struct {
	ItemID         uint            `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID    uint            `gorm:"primaryKey;autoIncrement:false"`
	TodoListFields []TodoListField `gorm:"foreignKey:TodoListItemID,WorkspaceID;references:ItemID,WorkspaceID"`
}

type Point struct {
	ID            uint    `gorm:"primaryKey;autoIncrement"`
	DrawingItemID uint    `gorm:"not null;index"`
	X             float64 `gorm:"not null"`
	Y             float64 `gorm:"not null"`
}

type DrawingItem struct {
	ItemID      uint `gorm:"primaryKey;autoIncrement:false"`
	WorkspaceID uint `gorm:"primaryKey;autoIncrement:false"`
	Points      []Point `gorm:"foreignKey:DrawingItemID;references:ItemID"`
}

// Assign a local, scoped within a workspace id to the item
func (i *Item) BeforeCreate(tx *gorm.DB) error {
	if i.ID != 0 {
		return nil
	}

	lastItem := &Item{}
	if err := tx.Where("workspace_id = ?", i.WorkspaceID).Last(lastItem).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			i.ID = 1 // first item in the workspace
			return nil
		}
		return err
	}

	i.ID = lastItem.ID + 1
	return nil
}

// Assign a local, scoped within a list in a workspace id to the todo list field
func (f *TodoListField) BeforeCreate(tx *gorm.DB) error {
	if f.ID != 0 {
		return nil
	}

	var maxID uint
	err := tx.Model(&TodoListField{}).
		Where("todo_list_item_id = ? AND workspace_id = ?",
			f.TodoListItemID,
			f.WorkspaceID).
		Select("COALESCE(MAX(id), 0)").
		Scan(&maxID).Error

	if err != nil {
		return err
	}

	f.ID = maxID + 1
	return nil
}
