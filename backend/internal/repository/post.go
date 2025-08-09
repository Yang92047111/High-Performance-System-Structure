package repository

import (
	"social-media-app/internal/model"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PostRepository struct {
	db *gorm.DB
}

func NewPostRepository(db *gorm.DB) *PostRepository {
	return &PostRepository{db: db}
}

func (r *PostRepository) Create(post *model.Post) error {
	return r.db.Create(post).Error
}

func (r *PostRepository) GetByID(id uuid.UUID) (*model.Post, error) {
	var post model.Post
	err := r.db.Preload("User").Preload("Messages.Sender").First(&post, "id = ?", id).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &post, nil
}

func (r *PostRepository) GetAll() ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.Preload("User").Order("created_at desc").Find(&posts).Error
	return posts, err
}

func (r *PostRepository) GetByUserID(userID uuid.UUID) ([]*model.Post, error) {
	var posts []*model.Post
	err := r.db.Preload("User").Where("user_id = ?", userID).Order("created_at desc").Find(&posts).Error
	return posts, err
}
