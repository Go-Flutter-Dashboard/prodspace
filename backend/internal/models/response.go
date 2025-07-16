package models

type UserRead struct {
	ID          uint   `json:"id" example:"12345"`
	Login       string `json:"username"`
	WorkspaceID uint   `json:"workspace_id"`
}

type TextItemRead struct {
	Content string `json:"content"`
}

type TodoListItemFieldRead struct {
	TextItemRead TextItemRead `json:"text"`
	Done         bool         `json:"done"`
}

type ImageItemRead struct {
	Bytes string `json:"bytes"`
}

type ShapeItemRead struct {
	Name string `json:"name"`
}

type DrawingPointRead struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type DrawingItemRead struct {
	Points []DrawingPointRead `json:"points"`
}

type ItemRead struct {
	ID           uint                     `json:"id"`
	PositionX    float64                  `json:"position_x"`
	PositionY    float64                  `json:"position_y"`
	ZIndex       uint                     `json:"z_index"`
	WorkspaceID  uint                     `json:"workspace_id"`
	Width        float64                  `json:"width"`
	Height       float64                  `json:"height"`
	Color        string                   `json:"color"`
	Scale        float64                  `json:"scale"`
	TextItem     *TextItemRead            `json:"text,omitempty"`
	ImageItem    *ImageItemRead           `json:"image,omitempty"`
	TodoListItem []TodoListItemFieldRead  `json:"todo_list,omitempty"`
	ShapeItem    *ShapeItemRead           `json:"shape,omitempty"`
	DrawingItem  *DrawingItemRead         `json:"drawing,omitempty"`
}

type WorkspaceRead struct {
	Items []ItemRead `json:"items"`
}

type MessageResponse struct {
	Message string `json:"message" example:"Descriptive message"`
}

type CreatedResponse struct {
	Message string `json:"message" example:"Resource created successfully"`
	ID      uint   `json:"id" example:"12345"`
}

type ErrorResponse struct {
	Error string `json:"error" example:"A descriptive error message"`
}

type CountResponse struct {
	Count int64 `json:"count" example:"10"`
}

type AuthResponse struct {
	Message string `json:"message"`
	Token   string `json:"token"`
	UserID  uint   `json:"user_id"`
}
