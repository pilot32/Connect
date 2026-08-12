const { z } = require('zod');
const prisma = require('../config/db');
const { serializeUser, serializeProfile } = require('../utils/serializers');
const { uploadImageBuffer } = require('../utils/imageUpload');

const idParamSchema = z.string().uuid();

const updateProfileSchema = z.object({
  name: z.string().min(1).optional(),
  designation: z.string().min(1).optional(),
  service: z.string().min(1).optional(),
  department: z.string().min(1).optional(),
  stateOrCadre: z.string().min(1).optional(),
  yearsInService: z.coerce.number().int().nonnegative().optional(),
  bio: z.string().optional(),
});

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

async function updateMyProfile(req, res, next) {
  try {
    const fields = updateProfileSchema.parse(req.body);
    const photoFile = req.file;

    if (Object.keys(fields).length === 0 && !photoFile) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    const data = { ...fields };
    if (photoFile) {
      data.photoUrl = await uploadImageBuffer(photoFile.buffer, photoFile.mimetype, 'govconnect/profile-photos');
    }

    const profile = await prisma.profile.update({
      where: { userId: req.user.sub },
      data,
      include: { user: true },
    });

    res.status(200).json({
      user: serializeUser(profile.user),
      profile: serializeProfile(profile),
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid profile update', details: err.issues });
    }
    if (err.code === 'P2025') {
      return res.status(404).json({ error: 'Profile not found' });
    }
    next(err);
  }
}

module.exports = { getMyProfile, getProfileById, updateMyProfile };
