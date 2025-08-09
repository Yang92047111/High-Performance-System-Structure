package service

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"social-media-app/internal/model"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
)

type UploadService struct {
	minioClient *minio.Client
	bucketName  string
}

func NewUploadService(minioClient *minio.Client, bucketName string) *UploadService {
	return &UploadService{
		minioClient: minioClient,
		bucketName:  bucketName,
	}
}

func (s *UploadService) UploadImage(file io.Reader, filename string, contentType string, size int64) (*model.UploadResponse, error) {
	// Generate unique filename
	ext := filepath.Ext(filename)
	uniqueFilename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().Unix(), ext)

	// Upload to MinIO
	ctx := context.Background()
	_, err := s.minioClient.PutObject(ctx, s.bucketName, uniqueFilename, file, size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to upload file: %w", err)
	}

	// Generate URL (in production, this would be a CDN URL)
	url := fmt.Sprintf("http://localhost:9000/%s/%s", s.bucketName, uniqueFilename)

	return &model.UploadResponse{
		URL:      url,
		Filename: uniqueFilename,
	}, nil
}
