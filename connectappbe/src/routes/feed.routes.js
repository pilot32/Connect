const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { requireApproved } = require('../middleware/approved');
const feedController = require('../controllers/feed.controller');
const upload = require('../middleware/upload');

router.use(requireAuth, requireApproved);

router.post('/', upload.single('photo'), feedController.createPost);
router.get('/', feedController.getFeed);

module.exports = router;
