package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Message struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	PostID    uuid.UUID `json:"post_id" gorm:"type:uuid;not null"`
	SenderID  uuid.UUID `json:"sender_id" gorm:"type:uuid;not null"`
	Message   string    `json:"message" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`

	// Relations
	Post   Post `json:"post,omitempty" gorm:"foreignKey:PostID"`
	Sender User `json:"sender" gorm:"foreignKey:SenderID"`
}

// BeforeCreate hook to generate UUID
func (m *Message) BeforeCreate(tx *gorm.DB) error {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	return nil
}

type CreateMessageRequest struct {
	Message string `json:"message" binding:"required,max=500"`
}
