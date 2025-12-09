const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: '🚀 Fullstack Application from Docker Hub!',
    version: process.env.npm_package_version || '1.0.0',
    timestamp: new Date().toISOString(),
    docker: true,
    built_with: 'GitHub Actions'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.listen(port, () => {
  console.log(`✅ Server running on port ${port}`);
});
