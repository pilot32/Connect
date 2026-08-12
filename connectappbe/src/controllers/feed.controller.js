const { z } = require('zod');
const prisma = require('../config/db');
const { serializePublicProfile } = require('../utils/serializers');
const { uploadImageBuffer } = require('../utils/imageUpload');

const createPostSchema = z.object({
  content: z.string().trim().min(1).max(2000),
});

function serializePost(post) {
  return {
    id: post.id,
    content: post.content,
    photoUrl: post.photoUrl,
    createdAt: post.createdAt,
    author: serializePublicProfile(post.author.id, post.author.profile),
  };
}

async function getNetworkAuthorIds(userId) {
  const connections = await prisma.connection.findMany({
    where: {
      status: 'accepted',
      OR: [{ requesterId: userId }, { recipientId: userId }],
    },
    select: { requesterId: true, recipientId: true },
  });

  const networkIds = connections.map((c) => (c.requesterId === userId ? c.recipientId : c.requesterId));
  return [userId, ...networkIds];
}

async function createPost(req, res, next) {
  try {
    const { content } = createPostSchema.parse(req.body);

    const photoFile = req.file;
    const photoUrl = photoFile
      ? await uploadImageBuffer(photoFile.buffer, photoFile.mimetype, 'govconnect/post-photos')
      : null;

    const post = await prisma.post.create({
      data: { authorId: req.user.sub, content, photoUrl },
      include: { author: { include: { profile: true } } },
    });

    res.status(201).json(serializePost(post));
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid post content', details: err.issues });
    }
    next(err);
  }
}

async function getFeed(req, res, next) {
  try {
    const authorIds = await getNetworkAuthorIds(req.user.sub);

    const posts = await prisma.post.findMany({
      where: { authorId: { in: authorIds } },
      orderBy: { createdAt: 'desc' },
      include: { author: { include: { profile: true } } },
    });

    res.status(200).json(posts.map(serializePost));
  } catch (err) {
    next(err);
  }
}

module.exports = { createPost, getFeed };
