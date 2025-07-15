package schemas

import (
)

type User struct {
	ID                 uint      `gorm:"primaryKey"`
	Login              string    `gorm:"uniqueIndex;not null"`
	Name               string    `gorm:"not null"`
	PasswordHash       string    `gorm:"not null" json:"-"`
}