package handler

import (
	"net/http"
	"social-media-app/internal/model"
	"social-media-app/internal/service"
	"social-media-app/internal/websocket"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MessageHandler struct {
	service *service.MessageService
	hub     *websocket.Hub
}

func NewMessageHandler(service *service.MessageService, hub *websocket.Hub) *MessageHandler {
	return &MessageHandler{
		service: service,
		hub:     hub,
	}
}

func (h *MessageHandler) CreateMessage(c *gin.Context) {
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	var req model.CreateMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Extract user ID from JWT token (set by middleware)
	senderID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	message, err := h.service.CreateMessage(postID, senderID.(uuid.UUID), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Broadcast to WebSocket clients if hub is available
	if h.hub != nil {
		h.hub.BroadcastToPost(postID.String(), message)
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Message created successfully",
		"data":    message,
	})
}

func (h *MessageHandler) GetMessages(c *gin.Context) {
	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}

	messages, err := h.service.GetMessagesByPostID(postID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"messages": messages,
	})
}
