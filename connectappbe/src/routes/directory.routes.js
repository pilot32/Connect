const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { requireApproved } = require('../middleware/approved');
const directoryController = require('../controllers/directory.controller');

router.use(requireAuth, requireApproved);

router.get('/', directoryController.search);

module.exports = router;
