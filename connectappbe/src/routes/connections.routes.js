const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const connectionsController = require('../controllers/connections.controller');

router.get('/', requireAuth, connectionsController.listMyConnections);
router.get('/requests', requireAuth, connectionsController.listRequests);
router.post('/request/:userId', requireAuth, connectionsController.sendRequest);
router.post('/:requestId/accept', requireAuth, connectionsController.acceptRequest);
router.post('/:requestId/decline', requireAuth, connectionsController.declineRequest);
router.delete('/:connectionId', requireAuth, connectionsController.deleteConnection);

module.exports = router;
