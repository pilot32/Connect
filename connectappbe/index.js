const app = require('./app');
const { port } = require('./src/config/env');

// 0.0.0.0 rather than the default loopback: Render (and Docker generally)
// routes external traffic to the container's public interface, so a server
// bound only to localhost is unreachable and the deploy fails health checks.
app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
