package repository

import (
	"social-media-app/internal/model"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MessageRepository struct {
	db *gorm.DB
}

func NewMessageRepository(db *gorm.DB) *MessageRepository {
	return &MessageRepository{db: db}
}

func (r *MessageRepository) Create(message *model.Message) error {
	return r.db.Create(message).Error
}

func (r *MessageRepository) GetByPostID(postID uuid.UUID) ([]*model.Message, error) {
	var messages []*model.Message
	err := r.db.Preload("Sender").Where("post_id = ?", postID).Order("created_at asc").Find(&messages).Error
	return messages, err
}

func (r *MessageRepository) GetByID(id uuid.UUID) (*model.Message, error) {
	var message model.Message
	err := r.db.Preload("Sender").First(&message, "id = ?", id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &message, nil
}
