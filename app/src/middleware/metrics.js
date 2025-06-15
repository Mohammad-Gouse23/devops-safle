const promClient = require('prom-client');

// Create a Registry to register the metrics
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({
  register,
  prefix: 'nodejs_',
});

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const activeConnections = new promClient.Gauge({
  name: 'nodejs_active_connections',
  help: 'Number of active connections'
});

const databaseConnections = new promClient.Gauge({
  name: 'nodejs_db_connections_active',
  help: 'Number of active database connections'
});

const databaseConnectionsTotal = new promClient.Gauge({
  name: 'nodejs_db_connections_total',
  help: 'Total number of database connections'
});

const businessMetrics = new promClient.Counter({
  name: 'business_events_total',
  help: 'Total number of business events',
  labelNames: ['event_type']
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestsTotal);
register.registerMetric(activeConnections);
register.registerMetric(databaseConnections);
register.registerMetric(databaseConnectionsTotal);
register.registerMetric(businessMetrics);

// Middleware function
const metricsMiddleware = (req, res, next) => {
  const start = Date.now();
  
  // Increment active connections
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    // Record metrics
    httpRequestDuration
      .labels(req.method, route, res.statusCode)
      .observe(duration);
    
    httpRequestsTotal
      .labels(req.method, route, res.statusCode)
      .inc();
    
    // Decrement active connections
    activeConnections.dec();
  });
  
  next();
};

// Health check function
const updateHealthMetrics = (dbPool) => {
  if (dbPool) {
    databaseConnections.set(dbPool.totalCount || 0);
    databaseConnectionsTotal.set(dbPool.size || 0);
  }
};

// Business event tracker
const trackBusinessEvent = (eventType) => {
  businessMetrics.labels(eventType).inc();
};

module.exports = {
  register,
  metricsMiddleware,
  updateHealthMetrics,
  trackBusinessEvent
};

