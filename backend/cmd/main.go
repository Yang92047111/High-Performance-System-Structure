package main

import (
	"log"

	"social-media-app/internal/config"
	"social-media-app/internal/database"
	"social-media-app/internal/handler"
	"social-media-app/internal/metrics"
	"social-media-app/internal/middleware"
	"social-media-app/internal/redis"
	"social-media-app/internal/repository"
	"social-media-app/internal/service"
	"social-media-app/internal/storage"
	"social-media-app/internal/websocket"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to database
	db, err := database.Connect(&cfg.Database)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Connect to Redis
	redisClient, err := redis.Connect(&cfg.Redis)
	if err != nil {
		log.Fatal("Failed to connect to Redis:", err)
	}

	// Connect to MinIO
	minioClient, err := storage.Connect(&cfg.MinIO)
	if err != nil {
		log.Fatal("Failed to connect to MinIO:", err)
	}

	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	postRepo := repository.NewPostRepository(db)
	messageRepo := repository.NewMessageRepository(db)

	// Initialize services
	redisService := service.NewRedisService(redisClient)
	userService := service.NewUserService(userRepo, cfg.JWT.Secret)
	postService := service.NewPostService(postRepo, redisService)
	messageService := service.NewMessageService(messageRepo, redisService)
	uploadService := service.NewUploadService(minioClient, cfg.MinIO.Bucket)

	// Initialize rate limiter
	rateLimiter := middleware.NewRateLimiter(redisClient)

	// Initialize handlers
	userHandler := handler.NewUserHandler(userService)
	postHandler := handler.NewPostHandler(postService)
	messageHandler := handler.NewMessageHandler(messageService, wsHub)
	uploadHandler := handler.NewUploadHandler(uploadService)

	// Setup Gin router
	r := gin.Default()

	// Global middleware
	r.Use(metrics.PrometheusMiddleware())
	r.Use(rateLimiter.GlobalRateLimit())

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Metrics endpoint
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// WebSocket endpoint
	r.GET("/ws", middleware.AuthMiddleware(cfg.JWT.Secret), wsHub.HandleWebSocket)

	// API routes
	api := r.Group("/api/v1")
	{
		// Public routes (no auth required)
		api.POST("/users/register", userHandler.Register)
		api.POST("/users/login", rateLimiter.LoginRateLimit(), userHandler.Login)
		api.GET("/posts", postHandler.GetPosts)
		api.GET("/posts/:id", postHandler.GetPost)
		api.GET("/posts/:id/messages", messageHandler.GetMessages)

		// Protected routes (auth required)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		{
			// User routes
			protected.GET("/users/profile", userHandler.GetProfile)

			// Post routes
			protected.POST("/posts", rateLimiter.PostCreationRateLimit(), postHandler.CreatePost)

			// Message routes
			protected.POST("/posts/:id/messages", rateLimiter.MessageRateLimit(), messageHandler.CreateMessage)

			// Upload routes
			protected.POST("/upload/image", uploadHandler.UploadImage)
		}
	}

	log.Printf("🚀 Server starting on port %s", cfg.Port)
	log.Printf("📊 Metrics available at /metrics")
	log.Printf("🔌 WebSocket endpoint at /ws")
	log.Printf("🗄️  Database: Connected to PostgreSQL")
	log.Printf("⚡ Redis: Connected with caching enabled")
	log.Printf("📦 MinIO: Connected (bucket: %s)", cfg.MinIO.Bucket)
	log.Printf("🛡️  Rate limiting: Enabled")

	r.Run(":" + cfg.Port)
}
