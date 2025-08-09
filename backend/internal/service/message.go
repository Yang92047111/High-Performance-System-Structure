package service

import (
	"social-media-app/internal/metrics"
	"social-media-app/internal/model"
	"social-media-app/internal/repository"

	"github.com/google/uuid"
)

type MessageService struct {
	repo         *repository.MessageRepository
	redisService *RedisService
}

func NewMessageService(repo *repository.MessageRepository, redisService *RedisService) *MessageService {
	return &MessageService{
		repo:         repo,
		redisService: redisService,
	}
}

func (s *MessageService) CreateMessage(postID, senderID uuid.UUID, req *model.CreateMessageRequest) (*model.Message, error) {
	message := &model.Message{
		PostID:   postID,
		SenderID: senderID,
		Message:  req.Message,
	}

	err := s.repo.Create(message)
	if err != nil {
		return nil, err
	}

	// Invalidate messages cache for this post
	s.redisService.InvalidatePostMessages(postID.String())

	// Increment metrics
	metrics.IncrementMessagesCreated()

	return message, nil
}

func (s *MessageService) GetMessagesByPostID(postID uuid.UUID) ([]*model.Message, error) {
	// Try cache first
	var cachedMessages []*model.Message
	err := s.redisService.GetCachedPostMessages(postID.String(), &cachedMessages)
	if err == nil && len(cachedMessages) > 0 {
		return cachedMessages, nil
	}

	// Cache miss, get from database
	messages, err := s.repo.GetByPostID(postID)
	if err != nil {
		return nil, err
	}

	// Cache the result
	if len(messages) > 0 {
		s.redisService.CachePostMessages(postID.String(), messages)
	}

	return messages, nil
}
