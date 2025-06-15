const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { metricsMiddleware, trackBusinessEvent } = require('./middleware/metrics');
const metricsRouter = require('./routes/metrics');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Metrics middleware (should be early in the stack)
app.use(metricsMiddleware);

// Metrics and health endpoints
app.use('/', metricsRouter);

// API routes
app.use('/api/users', require('./routes/users'));
app.use('/api/posts', require('./routes/posts'));

// Example business event tracking
app.post('/api/users', (req, res, next) => {
  trackBusinessEvent('user_created');
  next();
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  trackBusinessEvent('error_occurred');
  res.status(err.status || 500).json({
    message: err.message,
    error: process.env.NODE_ENV === 'production' ? {} : err
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    message: 'Route not found'
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Metrics available at: http://localhost:${PORT}/metrics`);
  console.log(`Health check at: http://localhost:${PORT}/health`);
});

module.exports = app;
