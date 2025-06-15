const express = require('express');
const { register } = require('../middleware/metrics');

const router = express.Router();

// Prometheus metrics endpoint
router.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate metrics' });
  }
});

// Health check endpoint with detailed status
router.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  };
  
  res.json(health);
});

// Readiness probe
router.get('/ready', (req, res) => {
  // Add checks for database, external services, etc.
  const ready = {
    status: 'ready',
    checks: {
      database: 'connected', // Replace with actual DB check
      memory: process.memoryUsage().heapUsed < 1000000000 // 1GB limit
    }
  };
  
  const allChecksPass = Object.values(ready.checks).every(check => 
    check === 'connected' || check === true
  );
  
  if (allChecksPass) {
    res.json(ready);
  } else {
    res.status(503).json(ready);
  }
});

module.exports = router;

