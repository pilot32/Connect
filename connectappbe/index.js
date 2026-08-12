const app = require('./app');
const { port } = require('./src/config/env');

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
