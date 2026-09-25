package storage

import (
	"context"
	"fmt"
	"io"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// R2Client wraps the S3 client for Cloudflare R2 operations
type R2Client struct {
	client            *s3.Client
	presignClient     *s3.PresignClient
	bucket            string
	uploadURLExpiry   time.Duration
	downloadURLExpiry time.Duration
}

// R2Config contains configuration for R2 client
type R2Config struct {
	AccountID         string
	AccessKeyID       string
	SecretAccessKey   string
	BucketName        string
	UploadURLExpiry   time.Duration // Default: 5 minutes
	DownloadURLExpiry time.Duration // Default: 1 hour
}

// NewR2Client creates a new R2 client with the given configuration
func NewR2Client(cfg R2Config) (*R2Client, error) {
	// R2 endpoint format
	endpoint := fmt.Sprintf("https://%s.r2.cloudflarestorage.com", cfg.AccountID)

	// Create custom resolver for R2 endpoint
	customResolver := aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
		return aws.Endpoint{
			URL: endpoint,
		}, nil
	})

	// Load AWS config with custom credentials and endpoint
	awsCfg, err := config.LoadDefaultConfig(context.Background(),
		config.WithRegion("auto"), // R2 uses "auto" region
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			cfg.AccessKeyID,
			cfg.SecretAccessKey,
			"",
		)),
		config.WithEndpointResolverWithOptions(customResolver),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to load R2 config: %w", err)
	}

	// Create S3 client
	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.UsePathStyle = true // R2 requires path-style addressing
	})

	// Set default expiry times
	uploadExpiry := cfg.UploadURLExpiry
	if uploadExpiry == 0 {
		uploadExpiry = 5 * time.Minute
	}
	downloadExpiry := cfg.DownloadURLExpiry
	if downloadExpiry == 0 {
		downloadExpiry = 1 * time.Hour
	}

	return &R2Client{
		client:            client,
		presignClient:     s3.NewPresignClient(client),
		bucket:            cfg.BucketName,
		uploadURLExpiry:   uploadExpiry,
		downloadURLExpiry: downloadExpiry,
	}, nil
}

// GenerateUploadURL creates a pre-signed URL for uploading a file
func (r *R2Client) GenerateUploadURL(ctx context.Context, key string, contentType string, contentLength int64) (string, time.Time, error) {
	expiresAt := time.Now().Add(r.uploadURLExpiry)

	presignedReq, err := r.presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(r.bucket),
		Key:           aws.String(key),
		ContentType:   aws.String(contentType),
		ContentLength: aws.Int64(contentLength),
	}, s3.WithPresignExpires(r.uploadURLExpiry))
	if err != nil {
		return "", time.Time{}, fmt.Errorf("failed to generate upload URL: %w", err)
	}

	return presignedReq.URL, expiresAt, nil
}

// GenerateDownloadURL creates a pre-signed URL for downloading a file
func (r *R2Client) GenerateDownloadURL(ctx context.Context, key string) (string, time.Time, error) {
	expiresAt := time.Now().Add(r.downloadURLExpiry)

	presignedReq, err := r.presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(r.downloadURLExpiry))
	if err != nil {
		return "", time.Time{}, fmt.Errorf("failed to generate download URL: %w", err)
	}

	return presignedReq.URL, expiresAt, nil
}

// DeleteObject removes a file from R2
func (r *R2Client) DeleteObject(ctx context.Context, key string) error {
	_, err := r.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return fmt.Errorf("failed to delete object: %w", err)
	}
	return nil
}

// UploadObject uploads a file directly (for server-side uploads)
func (r *R2Client) UploadObject(ctx context.Context, key string, body io.Reader, contentType string, contentLength int64) error {
	_, err := r.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(r.bucket),
		Key:           aws.String(key),
		Body:          body,
		ContentType:   aws.String(contentType),
		ContentLength: aws.Int64(contentLength),
	})
	if err != nil {
		return fmt.Errorf("failed to upload object: %w", err)
	}
	return nil
}

// GetObject retrieves a file from R2 (for server-side downloads)
func (r *R2Client) GetObject(ctx context.Context, key string) (io.ReadCloser, string, error) {
	output, err := r.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, "", fmt.Errorf("failed to get object: %w", err)
	}

	contentType := ""
	if output.ContentType != nil {
		contentType = *output.ContentType
	}

	return output.Body, contentType, nil
}

// HeadObject checks if an object exists and gets its metadata
func (r *R2Client) HeadObject(ctx context.Context, key string) (int64, string, error) {
	output, err := r.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(r.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return 0, "", err
	}

	size := int64(0)
	if output.ContentLength != nil {
		size = *output.ContentLength
	}

	contentType := ""
	if output.ContentType != nil {
		contentType = *output.ContentType
	}

	return size, contentType, nil
}
