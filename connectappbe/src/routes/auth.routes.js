const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const upload = require('../middleware/upload');

router.post(
  '/signup',
  upload.fields([
    { name: 'idCardPhoto', maxCount: 1 },
    { name: 'profilePhoto', maxCount: 1 },
  ]),
  authController.signup
);
router.post('/login', authController.login);

module.exports = router;
