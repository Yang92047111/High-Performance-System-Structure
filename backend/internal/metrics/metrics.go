package metrics

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// HTTP metrics
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)

	// Database metrics
	dbConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "db_connections_active",
			Help: "Number of active database connections",
		},
	)

	dbQueriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "db_queries_total",
			Help: "Total number of database queries",
		},
		[]string{"operation", "table"},
	)

	// Redis metrics
	redisConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "redis_connections_active",
			Help: "Number of active Redis connections",
		},
	)

	redisOperationsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "redis_operations_total",
			Help: "Total number of Redis operations",
		},
		[]string{"operation"},
	)

	// WebSocket metrics
	websocketConnectionsActive = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "websocket_connections_active",
			Help: "Number of active WebSocket connections",
		},
	)

	websocketMessagesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "websocket_messages_total",
			Help: "Total number of WebSocket messages",
		},
		[]string{"type"},
	)

	// Business metrics
	usersRegisteredTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "users_registered_total",
			Help: "Total number of registered users",
		},
	)

	postsCreatedTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "posts_created_total",
			Help: "Total number of posts created",
		},
	)

	messagesCreatedTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "messages_created_total",
			Help: "Total number of messages created",
		},
	)
)

// PrometheusMiddleware collects HTTP metrics
func PrometheusMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		duration := time.Since(start).Seconds()
		status := strconv.Itoa(c.Writer.Status())

		httpRequestsTotal.WithLabelValues(c.Request.Method, c.FullPath(), status).Inc()
		httpRequestDuration.WithLabelValues(c.Request.Method, c.FullPath()).Observe(duration)
	}
}

// Business metric helpers
func IncrementUserRegistrations() {
	usersRegisteredTotal.Inc()
}

func IncrementPostsCreated() {
	postsCreatedTotal.Inc()
}

func IncrementMessagesCreated() {
	messagesCreatedTotal.Inc()
}

func IncrementWebSocketConnections() {
	websocketConnectionsActive.Inc()
}

func DecrementWebSocketConnections() {
	websocketConnectionsActive.Dec()
}

func IncrementWebSocketMessages(messageType string) {
	websocketMessagesTotal.WithLabelValues(messageType).Inc()
}

func IncrementDBQueries(operation, table string) {
	dbQueriesTotal.WithLabelValues(operation, table).Inc()
}

func IncrementRedisOperations(operation string) {
	redisOperationsTotal.WithLabelValues(operation).Inc()
}

func SetActiveDBConnections(count float64) {
	dbConnectionsActive.Set(count)
}

func SetActiveRedisConnections(count float64) {
	redisConnectionsActive.Set(count)
}
