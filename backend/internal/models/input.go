package models

type UserCreate struct {
	Login    string `json:"login"    example:"john123"`
	Password string `json:"password" example:"123"`
}

type UserUpdate struct {
	OldPassword string  `json:"old_password" example:"123"`
	Login       string  `json:"login"        example:"john123"`
	NewPassword *string `json:"new_password" example:"234"`
}

type TextItemCreate struct {
	Content string `json:"content" example:"Hello, world!"`
}

type ImageItemCreate struct {
	Bytes string `json:"bytes"`
}

type TodoItemFieldCreate struct {
	TextItemCreate
	Done bool `json:"done"`
}

type ItemCreate struct {
	PositionX float64                `json:"position_x"          example:"1.0"`
	PositionY float64                `json:"position_y"          example:"1.0"`
	ZIndex    uint                   `json:"z_index"             example:"1"`
	TextItem  *TextItemCreate        `json:"text,omitempty"`
	ImageItem *ImageItemCreate       `json:"image,omitempty"`
	TodoList  *[]TodoItemFieldCreate `json:"todo_list,omitempty"`
}
