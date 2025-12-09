const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: '🚀 Fullstack Application Running in Kubernetes!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    hostname: process.env.HOSTNAME || 'localhost'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.get('/api/version', (req, res) => {
  res.json({
    version: '1.0.0',
    ci_cd: 'GitHub Actions + Kind',
    deployed_at: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`✅ Application running on port ${port}`);
  console.log(`📡 Health endpoint: http://0.0.0.0:${port}/health`);
});
