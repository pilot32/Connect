const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const profileController = require('../controllers/profile.controller');
const upload = require('../middleware/upload');

router.get('/me', requireAuth, profileController.getMyProfile);
router.put('/me', requireAuth, upload.single('photo'), profileController.updateMyProfile);
router.get('/:id', requireAuth, profileController.getProfileById);

module.exports = router;
