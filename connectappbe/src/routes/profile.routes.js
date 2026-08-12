const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const profileController = require('../controllers/profile.controller');

router.get('/me', requireAuth, profileController.getMyProfile);
router.get('/:id', requireAuth, profileController.getProfileById);

module.exports = router;
