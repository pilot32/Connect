const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/profile', require('./profile.routes'));
router.use('/connections', require('./connections.routes'));
router.use('/directory', require('./directory.routes'));
router.use('/feed', require('./feed.routes'));

// verification router is not yet implemented (empty stub file) — mount it
// here once its controller exists.

module.exports = router;
