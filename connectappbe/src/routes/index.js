const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));

// profile/verification/directory/connections/feed routers are not yet
// implemented (empty stub files) — mount them here once their controllers exist.

module.exports = router;
