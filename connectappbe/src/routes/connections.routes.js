const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { requireApproved } = require('../middleware/approved');
const connectionsController = require('../controllers/connections.controller');

router.use(requireAuth, requireApproved);

router.get('/', connectionsController.listMyConnections);
router.get('/requests', connectionsController.listRequests);
router.post('/request/:userId', connectionsController.sendRequest);
router.post('/:requestId/accept', connectionsController.acceptRequest);
router.post('/:requestId/decline', connectionsController.declineRequest);
router.delete('/:connectionId', connectionsController.deleteConnection);

module.exports = router;
