package models

import (
	"time"
)

type UserRead struct {
	ID       uint   `json:"id" example:"12345"`
	Login    string `json:"username"`
	UserName string `json:"name" example:"John"`
}

type ExerciseSetRead struct {
	Weight     float64 `json:"weight"      example:"10"`
	Reps       uint    `json:"reps"        example:"10"`
	ExerciseID uint    `json:"exercise_id" example:"10"`
	WorkoutID  uint    `json:"-"           example:"10"`
}

type WorkoutRead struct {
	ID           uint              `json:"id" example:"1"`
	DurationNS   int64             `json:"duration_ns" example:"60"` // in nanoseconds
	Timestamp    time.Time         `json:"timestamp" example:"2023-10-01T12:00:00Z"`
	UserID       uint              `json:"user_id" example:"12345"`
	ExerciseSets []ExerciseSetRead `json:"exercise_sets"`
}

type ExerciseRead struct {
	ID           uint     `json:"id" example:"1"`
	Name         string   `json:"name"`
	Description  string   `json:"description" example:"Push-ups are a basic exercise that works the chest, shoulders, and triceps."`
	MuscleGroups []string `json:"muscle_groups" example:"chest,back,triceps"`
	URL          string   `json:"url" example:"https://example.com/image.jpg"` // URL to the exercise image
}

type MessageResponse struct {
	Message string `json:"message" example:"Descriptive message"`
}

type CreatedResponse struct {
	Message string `json:"message" example:"User created successfully"`
	ID      uint   `json:"id" example:"12345"`
}

type ErrorResponse struct {
	Error string `json:"error" example:"A descriptive error message"`
}

type CountResponse struct {
	Count int64 `json:"count" example:"10"`
}
