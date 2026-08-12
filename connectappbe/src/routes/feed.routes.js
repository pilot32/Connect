const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const feedController = require('../controllers/feed.controller');
const upload = require('../middleware/upload');

router.post('/', requireAuth, upload.single('photo'), feedController.createPost);
router.get('/', requireAuth, feedController.getFeed);

module.exports = router;
