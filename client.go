package clo_cloud_sdk

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"time"
)

func NewCLOClient(token string, opts ...Option) (ClientWithResponsesInterface, error) {
	config := &clientConfig{
		baseURL: "https://api.clo.ru",
		timeout: 30 * time.Second,
		logger:  slog.Default(),
	}

	for _, opt := range opts {
		opt(config)
	}

	httpClient := &http.Client{
		Timeout: config.timeout,
		Transport: &LoggingRoundTripper{
			Proxied: http.DefaultTransport,
			Logger:  config.logger,
		},
	}

	return NewClientWithResponses(
		config.baseURL,
		WithHTTPClient(httpClient),
		WithRequestEditorFn(withAuthToken(token)),
	)
}

type LoggingRoundTripper struct {
	Proxied http.RoundTripper
	Logger  Logger // Теперь здесь интерфейс
}

func (l *LoggingRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	start := time.Now()
	resp, err := l.Proxied.RoundTrip(req)
	duration := time.Since(start)

	attrs := []slog.Attr{
		slog.String("method", req.Method),
		slog.String("url", req.URL.String()),
		slog.Duration("duration", duration),
	}

	if err != nil {
		attrs = append(attrs, slog.String("error", err.Error()))
		l.Logger.LogAttrs(req.Context(), slog.LevelError, "HTTP request failed", attrs...)
		return nil, err
	}

	attrs = append(attrs, slog.Int("status", resp.StatusCode))

	// Логика определения уровня лога
	level := slog.LevelInfo
	if resp.StatusCode >= 400 {
		level = slog.LevelWarn
	}
	if resp.StatusCode >= 500 {
		level = slog.LevelError
	}

	l.Logger.LogAttrs(req.Context(), level, "HTTP request processed", attrs...)

	return resp, nil
}

type Logger interface {
	LogAttrs(ctx context.Context, level slog.Level, msg string, attrs ...slog.Attr)
}

type clientConfig struct {
	baseURL string
	timeout time.Duration
	logger  *slog.Logger
}

type Option func(*clientConfig)

func WithTimeout(t time.Duration) Option {
	return func(c *clientConfig) { c.timeout = t }
}

func WithLogger(l *slog.Logger) Option {
	return func(c *clientConfig) { c.logger = l }
}

func withAuthToken(token string) RequestEditorFn {
	return func(ctx context.Context, req *http.Request) error {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))
		return nil
	}
}
