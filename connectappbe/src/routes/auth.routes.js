const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const upload = require('../middleware/upload');
const { requireAuth } = require('../middleware/auth');

router.post(
  '/signup',
  upload.fields([
    { name: 'idCardPhoto', maxCount: 1 },
    { name: 'profilePhoto', maxCount: 1 },
  ]),
  authController.signup
);
router.post('/login', authController.login);
// Deliberately requireAuth only, no requireApproved — a pending user has to be
// able to read their own status.
router.get('/status', requireAuth, authController.getStatus);

module.exports = router;
