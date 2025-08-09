package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Post struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	UserID    uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	ImageURL  string    `json:"image_url"`
	Caption   string    `json:"caption"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Relations
	User     User      `json:"user" gorm:"foreignKey:UserID"`
	Messages []Message `json:"messages,omitempty" gorm:"foreignKey:PostID"`
}

// BeforeCreate hook to generate UUID
func (p *Post) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

type CreatePostRequest struct {
	ImageURL string `json:"image_url" binding:"required"`
	Caption  string `json:"caption"`
}
type UploadResponse struct {
	URL      string `json:"url"`
	Filename string `json:"filename"`
}
