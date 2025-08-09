package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"golang.org/x/time/rate"
)

type RateLimiter struct {
	redisClient *redis.Client
	limiter     *rate.Limiter
}

func NewRateLimiter(redisClient *redis.Client) *RateLimiter {
	return &RateLimiter{
		redisClient: redisClient,
		limiter:     rate.NewLimiter(rate.Every(time.Second), 100), // 100 requests per second
	}
}

// Global rate limiter using token bucket
func (rl *RateLimiter) GlobalRateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !rl.limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "Rate limit exceeded",
				"retry_after": "1s",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Per-user rate limiter using Redis
func (rl *RateLimiter) UserRateLimit(requestsPerMinute int) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user identifier (IP or user ID)
		var identifier string
		if userID, exists := c.Get("user_id"); exists {
			identifier = fmt.Sprintf("user:%s", userID)
		} else {
			identifier = fmt.Sprintf("ip:%s", c.ClientIP())
		}

		key := fmt.Sprintf("rate_limit:%s", identifier)

		// Use Redis sliding window rate limiting
		ctx := c.Request.Context()

		// Get current count
		current, err := rl.redisClient.Get(ctx, key).Int()
		if err != nil && err != redis.Nil {
			// If Redis is down, allow the request
			c.Next()
			return
		}

		if current >= requestsPerMinute {
			// Get TTL for retry-after header
			ttl, _ := rl.redisClient.TTL(ctx, key).Result()

			c.Header("X-RateLimit-Limit", strconv.Itoa(requestsPerMinute))
			c.Header("X-RateLimit-Remaining", "0")
			c.Header("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(ttl).Unix(), 10))

			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "Rate limit exceeded",
				"retry_after": ttl.String(),
			})
			c.Abort()
			return
		}

		// Increment counter
		pipe := rl.redisClient.Pipeline()
		pipe.Incr(ctx, key)
		pipe.Expire(ctx, key, time.Minute)
		_, err = pipe.Exec(ctx)

		if err != nil {
			// If Redis is down, allow the request
			c.Next()
			return
		}

		// Set rate limit headers
		c.Header("X-RateLimit-Limit", strconv.Itoa(requestsPerMinute))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(requestsPerMinute-current-1))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(time.Minute).Unix(), 10))

		c.Next()
	}
}

// API endpoint specific rate limits
func (rl *RateLimiter) LoginRateLimit() gin.HandlerFunc {
	return rl.UserRateLimit(5) // 5 login attempts per minute
}

func (rl *RateLimiter) PostCreationRateLimit() gin.HandlerFunc {
	return rl.UserRateLimit(10) // 10 posts per minute
}

func (rl *RateLimiter) MessageRateLimit() gin.HandlerFunc {
	return rl.UserRateLimit(60) // 60 messages per minute
}
