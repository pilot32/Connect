function notFound(req, res) {
  res.status(404).json({ error: 'Route not found' });
}

function errorHandler(err, req, res, next) {
  console.error(err);
  const status = err.status || (err.name === 'MulterError' ? 400 : 500);
  const message = status < 500 ? err.message : 'Internal server error';
  res.status(status).json({ error: message });
}

module.exports = { notFound, errorHandler };
