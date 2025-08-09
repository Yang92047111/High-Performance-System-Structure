package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisService struct {
	client *redis.Client
}

func NewRedisService(client *redis.Client) *RedisService {
	return &RedisService{client: client}
}

// Cache operations
func (s *RedisService) Set(key string, value interface{}, expiration time.Duration) error {
	ctx := context.Background()

	jsonValue, err := json.Marshal(value)
	if err != nil {
		return err
	}

	return s.client.Set(ctx, key, jsonValue, expiration).Err()
}

func (s *RedisService) Get(key string, dest interface{}) error {
	ctx := context.Background()

	val, err := s.client.Get(ctx, key).Result()
	if err != nil {
		return err
	}

	return json.Unmarshal([]byte(val), dest)
}

func (s *RedisService) Delete(key string) error {
	ctx := context.Background()
	return s.client.Del(ctx, key).Err()
}

// Pub/Sub operations
func (s *RedisService) Publish(channel string, message interface{}) error {
	ctx := context.Background()

	jsonMessage, err := json.Marshal(message)
	if err != nil {
		return err
	}

	return s.client.Publish(ctx, channel, jsonMessage).Err()
}

func (s *RedisService) Subscribe(channel string) *redis.PubSub {
	ctx := context.Background()
	return s.client.Subscribe(ctx, channel)
}

// Helper methods for common cache keys
func (s *RedisService) CachePost(postID string, post interface{}) error {
	key := fmt.Sprintf("post:%s", postID)
	return s.Set(key, post, 10*time.Minute)
}

func (s *RedisService) GetCachedPost(postID string, dest interface{}) error {
	key := fmt.Sprintf("post:%s", postID)
	return s.Get(key, dest)
}

func (s *RedisService) InvalidatePostCache(postID string) error {
	key := fmt.Sprintf("post:%s", postID)
	return s.Delete(key)
}

// Cache posts feed
func (s *RedisService) CachePostsFeed(posts interface{}) error {
	return s.Set("posts:feed", posts, 5*time.Minute)
}

func (s *RedisService) GetCachedPostsFeed(dest interface{}) error {
	return s.Get("posts:feed", dest)
}

func (s *RedisService) InvalidatePostsFeed() error {
	return s.Delete("posts:feed")
}

// Cache user profile
func (s *RedisService) CacheUserProfile(userID string, user interface{}) error {
	key := fmt.Sprintf("user:%s", userID)
	return s.Set(key, user, 30*time.Minute)
}

func (s *RedisService) GetCachedUserProfile(userID string, dest interface{}) error {
	key := fmt.Sprintf("user:%s", userID)
	return s.Get(key, dest)
}

func (s *RedisService) InvalidateUserProfile(userID string) error {
	key := fmt.Sprintf("user:%s", userID)
	return s.Delete(key)
}

// Cache post messages
func (s *RedisService) CachePostMessages(postID string, messages interface{}) error {
	key := fmt.Sprintf("messages:%s", postID)
	return s.Set(key, messages, 2*time.Minute)
}

func (s *RedisService) GetCachedPostMessages(postID string, dest interface{}) error {
	key := fmt.Sprintf("messages:%s", postID)
	return s.Get(key, dest)
}

func (s *RedisService) InvalidatePostMessages(postID string) error {
	key := fmt.Sprintf("messages:%s", postID)
	return s.Delete(key)
}

// Session management
func (s *RedisService) StoreSession(sessionID string, data interface{}) error {
	key := fmt.Sprintf("session:%s", sessionID)
	return s.Set(key, data, 24*time.Hour)
}

func (s *RedisService) GetSession(sessionID string, dest interface{}) error {
	key := fmt.Sprintf("session:%s", sessionID)
	return s.Get(key, dest)
}

func (s *RedisService) DeleteSession(sessionID string) error {
	key := fmt.Sprintf("session:%s", sessionID)
	return s.Delete(key)
}
