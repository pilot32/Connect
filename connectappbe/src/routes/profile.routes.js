const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { requireApproved } = require('../middleware/approved');
const profileController = require('../controllers/profile.controller');
const upload = require('../middleware/upload');

router.use(requireAuth, requireApproved);

router.get('/me', profileController.getMyProfile);
router.put('/me', upload.single('photo'), profileController.updateMyProfile);
router.get('/:id', profileController.getProfileById);

module.exports = router;
