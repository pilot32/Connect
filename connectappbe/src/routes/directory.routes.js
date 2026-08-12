const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const directoryController = require('../controllers/directory.controller');

router.get('/', requireAuth, directoryController.search);

module.exports = router;
