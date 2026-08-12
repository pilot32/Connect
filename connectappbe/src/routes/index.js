const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/profile', require('./profile.routes'));
router.use('/connections', require('./connections.routes'));
router.use('/directory', require('./directory.routes'));

// verification/feed routers are not yet implemented (empty stub files) —
// mount them here once their controllers exist.

module.exports = router;
