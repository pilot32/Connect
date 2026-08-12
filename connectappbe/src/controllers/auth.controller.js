const { z } = require('zod');
const prisma = require('../config/db');
const { hashPassword, comparePassword } = require('../utils/password');
const { signToken } = require('../utils/jwt');
const { uploadImageBuffer } = require('../utils/imageUpload');
const { serializeUser, serializeProfile } = require('../utils/serializers');

const credentialsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const signupSchema = credentialsSchema.extend({
  name: z.string().min(1),
  designation: z.string().min(1),
  service: z.string().min(1),
  department: z.string().min(1),
  stateOrCadre: z.string().min(1),
  yearsInService: z.coerce.number().int().nonnegative(),
  bio: z.string().optional(),
});

async function signup(req, res, next) {
  try {
    const parsed = signupSchema.parse(req.body);

    const idCardFile = req.files?.idCardPhoto?.[0];
    if (!idCardFile) {
      return res.status(400).json({ error: 'ID card photo is required' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email: parsed.email } });
    if (existingUser) {
      return res.status(409).json({ error: 'Email is already registered' });
    }

    const passwordHash = await hashPassword(parsed.password);
    const idCardPhotoUrl = await uploadImageBuffer(
      idCardFile.buffer,
      idCardFile.mimetype,
      'govconnect/id-cards'
    );

    const profilePhotoFile = req.files?.profilePhoto?.[0];
    const profilePhotoUrl = profilePhotoFile
      ? await uploadImageBuffer(profilePhotoFile.buffer, profilePhotoFile.mimetype, 'govconnect/profile-photos')
      : null;

    const { user, profile } = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: { email: parsed.email, passwordHash, idCardPhotoUrl },
      });
      const createdProfile = await tx.profile.create({
        data: {
          userId: createdUser.id,
          name: parsed.name,
          photoUrl: profilePhotoUrl,
          designation: parsed.designation,
          service: parsed.service,
          department: parsed.department,
          stateOrCadre: parsed.stateOrCadre,
          yearsInService: parsed.yearsInService,
          bio: parsed.bio,
        },
      });
      return { user: createdUser, profile: createdProfile };
    });

    const token = signToken({ sub: user.id, email: user.email });
    res.status(201).json({
      token,
      user: serializeUser(user),
      profile: serializeProfile(profile),
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid signup details', details: err.issues });
    }
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = credentialsSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const passwordMatches = await comparePassword(password, user.passwordHash);
    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = signToken({ sub: user.id, email: user.email });
    res.status(200).json({ token, user: serializeUser(user) });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid email or password', details: err.issues });
    }
    next(err);
  }
}

module.exports = { signup, login };
