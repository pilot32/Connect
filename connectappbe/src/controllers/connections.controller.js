const { z } = require('zod');
const prisma = require('../config/db');
const { serializePublicProfile } = require('../utils/serializers');

const idParamSchema = z.string().uuid();

async function findExistingConnection(userAId, userBId) {
  return prisma.connection.findFirst({
    where: {
      OR: [
        { requesterId: userAId, recipientId: userBId },
        { requesterId: userBId, recipientId: userAId },
      ],
    },
  });
}

async function sendRequest(req, res, next) {
  try {
    const idResult = idParamSchema.safeParse(req.params.userId);
    if (!idResult.success) {
      return res.status(400).json({ error: 'Invalid user id' });
    }
    const recipientId = idResult.data;
    const requesterId = req.user.sub;

    if (recipientId === requesterId) {
      return res.status(400).json({ error: 'Cannot send a connection request to yourself' });
    }

    const recipientUser = await prisma.user.findUnique({ where: { id: recipientId } });
    if (!recipientUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    const existing = await findExistingConnection(requesterId, recipientId);
    if (existing) {
      return res.status(409).json({ error: 'A connection already exists between these users' });
    }

    const connection = await prisma.connection.create({
      data: { requesterId, recipientId },
    });

    res.status(201).json({
      requestId: connection.id,
      status: connection.status,
      createdAt: connection.createdAt,
    });
  } catch (err) {
    next(err);
  }
}

async function resolveRequestForAction(req, res) {
  const idResult = idParamSchema.safeParse(req.params.requestId);
  if (!idResult.success) {
    res.status(400).json({ error: 'Invalid request id' });
    return null;
  }

  const connection = await prisma.connection.findUnique({ where: { id: idResult.data } });
  if (!connection) {
    res.status(404).json({ error: 'Connection request not found' });
    return null;
  }

  if (connection.recipientId !== req.user.sub) {
    res.status(403).json({ error: 'Only the recipient can respond to this request' });
    return null;
  }

  if (connection.status !== 'pending') {
    res.status(409).json({ error: `Request is already ${connection.status}` });
    return null;
  }

  return connection;
}

async function acceptRequest(req, res, next) {
  try {
    const connection = await resolveRequestForAction(req, res);
    if (!connection) return;

    const updated = await prisma.connection.update({
      where: { id: connection.id },
      data: { status: 'accepted' },
    });

    res.status(200).json({
      requestId: updated.id,
      status: updated.status,
      updatedAt: updated.updatedAt,
    });
  } catch (err) {
    next(err);
  }
}

async function declineRequest(req, res, next) {
  try {
    const connection = await resolveRequestForAction(req, res);
    if (!connection) return;

    const updated = await prisma.connection.update({
      where: { id: connection.id },
      data: { status: 'declined' },
    });

    res.status(200).json({
      requestId: updated.id,
      status: updated.status,
      updatedAt: updated.updatedAt,
    });
  } catch (err) {
    next(err);
  }
}

async function listMyConnections(req, res, next) {
  try {
    const userId = req.user.sub;

    const connections = await prisma.connection.findMany({
      where: {
        status: 'accepted',
        OR: [{ requesterId: userId }, { recipientId: userId }],
      },
      include: {
        requester: { include: { profile: true } },
        recipient: { include: { profile: true } },
      },
    });

    const results = connections.map((connection) => {
      const other = connection.requesterId === userId ? connection.recipient : connection.requester;
      return {
        connectionId: connection.id,
        since: connection.updatedAt,
        user: serializePublicProfile(other.id, other.profile),
      };
    });

    res.status(200).json(results);
  } catch (err) {
    next(err);
  }
}

async function listRequests(req, res, next) {
  try {
    const userId = req.user.sub;

    const [incoming, outgoing] = await Promise.all([
      prisma.connection.findMany({
        where: { recipientId: userId, status: 'pending' },
        include: { requester: { include: { profile: true } } },
      }),
      prisma.connection.findMany({
        where: { requesterId: userId, status: 'pending' },
        include: { recipient: { include: { profile: true } } },
      }),
    ]);

    res.status(200).json({
      incoming: incoming.map((c) => ({
        requestId: c.id,
        status: c.status,
        createdAt: c.createdAt,
        user: serializePublicProfile(c.requester.id, c.requester.profile),
      })),
      outgoing: outgoing.map((c) => ({
        requestId: c.id,
        status: c.status,
        createdAt: c.createdAt,
        user: serializePublicProfile(c.recipient.id, c.recipient.profile),
      })),
    });
  } catch (err) {
    next(err);
  }
}

async function deleteConnection(req, res, next) {
  try {
    const idResult = idParamSchema.safeParse(req.params.connectionId);
    if (!idResult.success) {
      return res.status(400).json({ error: 'Invalid connection id' });
    }

    const userId = req.user.sub;
    const connection = await prisma.connection.findUnique({ where: { id: idResult.data } });
    if (!connection) {
      return res.status(404).json({ error: 'Connection not found' });
    }

    const isParty = connection.requesterId === userId || connection.recipientId === userId;
    if (!isParty) {
      return res.status(403).json({ error: 'Not part of this connection' });
    }

    if (connection.status === 'pending' && connection.requesterId !== userId) {
      return res.status(403).json({ error: 'Only the requester can cancel a pending request' });
    }

    await prisma.connection.delete({ where: { id: connection.id } });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = {
  sendRequest,
  acceptRequest,
  declineRequest,
  listMyConnections,
  listRequests,
  deleteConnection,
};
