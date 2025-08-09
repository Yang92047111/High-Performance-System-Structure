package service

import (
	"social-media-app/internal/metrics"
	"social-media-app/internal/model"
	"social-media-app/internal/repository"

	"github.com/google/uuid"
)

type PostService struct {
	repo         *repository.PostRepository
	redisService *RedisService
}

func NewPostService(repo *repository.PostRepository, redisService *RedisService) *PostService {
	return &PostService{
		repo:         repo,
		redisService: redisService,
	}
}

func (s *PostService) CreatePost(userID uuid.UUID, req *model.CreatePostRequest) (*model.Post, error) {
	post := &model.Post{
		UserID:   userID,
		ImageURL: req.ImageURL,
		Caption:  req.Caption,
	}

	err := s.repo.Create(post)
	if err != nil {
		return nil, err
	}

	// Invalidate posts feed cache
	s.redisService.InvalidatePostsFeed()

	// Increment metrics
	metrics.IncrementPostsCreated()

	return post, nil
}

func (s *PostService) GetPost(id uuid.UUID) (*model.Post, error) {
	// Try cache first
	var cachedPost model.Post
	err := s.redisService.GetCachedPost(id.String(), &cachedPost)
	if err == nil {
		return &cachedPost, nil
	}

	// Cache miss, get from database
	post, err := s.repo.GetByID(id)
	if err != nil {
		return nil, err
	}

	if post != nil {
		// Cache the result
		s.redisService.CachePost(id.String(), post)
	}

	return post, nil
}

func (s *PostService) GetAllPosts() ([]*model.Post, error) {
	// Try cache first
	var cachedPosts []*model.Post
	err := s.redisService.GetCachedPostsFeed(&cachedPosts)
	if err == nil && len(cachedPosts) > 0 {
		return cachedPosts, nil
	}

	// Cache miss, get from database
	posts, err := s.repo.GetAll()
	if err != nil {
		return nil, err
	}

	// Cache the result
	if len(posts) > 0 {
		s.redisService.CachePostsFeed(posts)
	}

	return posts, nil
}

func (s *PostService) GetUserPosts(userID uuid.UUID) ([]*model.Post, error) {
	return s.repo.GetByUserID(userID)
}
