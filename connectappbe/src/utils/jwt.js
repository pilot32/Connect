const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');

const TOKEN_EXPIRY = '7d';

function signToken(payload) {
  return jwt.sign(payload, jwtSecret, { expiresIn: TOKEN_EXPIRY });
}

function verifyToken(token) {
  return jwt.verify(token, jwtSecret);
}

module.exports = { signToken, verifyToken };
