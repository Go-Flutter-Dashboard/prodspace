package models

import (
	"time"
)

type UserCreate struct {
	Login    string `json:"login"    example:"john123"`
	Name     string `json:"name"     example:"John"`
	Surname  string `json:"surname"  example:"Wick"`
	Email    string `json:"email"    example:"john_doe@gmail.com"`
	Password string `json:"password" example:"123"`
}

type ExerciseSetCreate struct {
	Reps       uint    `json:"reps"        example:"10"`
	Weight     float64 `json:"weight"      example:"10"`
	ExerciseID uint    `json:"exercise_id" example:"10"`
}

type WorkoutCreate struct {
	UserID       uint                `json:"user_id"     example:"12345"`
	DurationNS   int64               `json:"duration_ns" example:"60"` // in nanoseconds
	StartTime    time.Time           `json:"start_time"  example:"2023-10-01T12:00:00Z"`
	ExerciseSets []ExerciseSetCreate `json:"exercise_sets"`
}

type ExerciseCreate struct {
	Name         string   `json:"name"`
	Description  string   `json:"description"   example:"Push-ups are a basic exercise that works the chest, shoulders, and triceps."`
	MuscleGroups []string `json:"muscle_groups" example:"chest,back,triceps"`
	URL          string   `json:"url"`
}

type ExerciseUpdate struct {
	Name         *string   `json:"url"`
	Description  *string   `json:"description"  example:"Push-ups are a basic exercise that works the chest, shoulders, and triceps."`
	MuscleGroups *[]string `json:"muscle_group" example:"chest,back,triceps"`
	URL          *string   `json:"image_path"   example:"https://example.com/image.jpg"` // URL to the exercise image
}

type UserUpdate struct {
	Login                    *string    `json:"login"`
	Name                     *string    `json:"name" example:"John"`
	Surname                  *string    `json:"surname"`
	Email                    *string    `json:"email" example:"john_doe@gmail.com"`
	SubscriptionPlan         *string    `json:"subscription_plan" example:"free"`
	SubscriptionStatus       *string    `json:"subscription_status" example:"active"`
	Status                   *string    `json:"status" example:"active"` // e.g., "active", "inactive", "banned"
	LastActivity             *time.Time `json:"last_activity" example:"2023-10-01T12:00:00Z"`
	NumberOfWorkouts         *uint      `json:"number_of_workouts" example:"0"`
	TotalTimeSpentNS         *int64     `json:"total_time_spent_ns" example:"3600"` // in seconds
	StreakCount              *uint      `json:"streak_count" example:"0"`
	AverageWorkoutDurationNS *int64     `json:"average_workout_duration_ns" example:"3600"` // in seconds
	Password                 *string    `json:"password"`
}

type WorkoutUpdate struct {
	UserID       *uint                `json:"user_id"     example:"12345"`
	DurationNS   *int64               `json:"duration_ns" example:"60"`
	StartTime    *time.Time           `json:"start_time"  example:"2023-10-01T12:00:00Z"`
	ExerciseSets *[]ExerciseSetCreate `json:"exercise_sets"`
}

type AuthInput struct {
	Login    string `json:"login"`
	Password string `json:"password"`
}

type UserActivityCreate struct {
	UserID uint      `json:"user_id" example:"12345"`
	Date   time.Time `json:"date"`
}