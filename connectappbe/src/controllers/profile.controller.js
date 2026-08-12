const { z } = require('zod');
const prisma = require('../config/db');
const { serializeUser, serializeProfile } = require('../utils/serializers');

const idParamSchema = z.string().uuid();

async function getMyProfile(req, res, next) {
  try {
    const profile = await prisma.profile.findUnique({
      where: { userId: req.user.sub },
      include: { user: true },
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.status(200).json({
      user: serializeUser(profile.user),
      profile: serializeProfile(profile),
    });
  } catch (err) {
    next(err);
  }
}

async function getProfileById(req, res, next) {
  try {
    const idResult = idParamSchema.safeParse(req.params.id);
    if (!idResult.success) {
      return res.status(400).json({ error: 'Invalid user id' });
    }

    const profile = await prisma.profile.findUnique({
      where: { userId: idResult.data },
    });

    if (!profile) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.status(200).json({
      user: { id: profile.userId },
      profile: serializeProfile(profile),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { getMyProfile, getProfileById };
