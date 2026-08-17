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

// `role`/`status` are carried in the token so a client can route straight to
// the admin console or the "awaiting approval" screen without a second call.
// They are a snapshot from sign-in time — the gate middleware re-reads the row,
// so a stale claim here can never widen access.
function tokenPayload(user) {
  return { sub: user.id, email: user.email, role: user.role, status: user.status };
}

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
        // role/status are the schema defaults, but spelled out here because a
        // signup landing in `pending` is the point of the whole feature.
        data: { email: parsed.email, passwordHash, idCardPhotoUrl, role: 'user', status: 'pending' },
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

    const token = signToken(tokenPayload(user));
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

    const user = await prisma.user.findUnique({
      where: { email },
      include: { profile: true },
    });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const passwordMatches = await comparePassword(password, user.passwordHash);
    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Pending and rejected accounts are still allowed to log in — they need a
    // token to poll GET /auth/status and see where their application stands.
    // requireApproved is what keeps them out of the app's features.
    const token = signToken(tokenPayload(user));
    res.status(200).json({
      token,
      user: serializeUser(user),
      profile: user.profile ? serializeProfile(user.profile) : null,
    });
  } catch (err) {
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: 'Invalid email or password', details: err.issues });
    }
    next(err);
  }
}

// Lets the app re-check approval in real time without forcing a re-login, since
// the token's `status` claim is frozen at sign-in.
async function getStatus(req, res, next) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.sub },
      include: { profile: true },
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    res.status(200).json({
      user: serializeUser(user),
      profile: user.profile ? serializeProfile(user.profile) : null,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { signup, login, getStatus };
