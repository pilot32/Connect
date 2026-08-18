const { z } = require('zod');
const prisma = require('../config/db');
const { serializeAdminApplicant } = require('../utils/serializers');

const idParamSchema = z.string().uuid();

const listQuerySchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected', 'all']).default('pending'),
});

const rejectBodySchema = z.object({
  reason: z.string().trim().min(1).max(500).optional(),
});

// Every admin endpoint deals in applicants, never in other admins: an admin
// account has no profile and no ID card, so it has nothing to review.
const APPLICANT_WHERE = { role: 'user' };

async function getUsers(req, res, next) {
  try {
    const query = listQuerySchema.safeParse(req.query);
    if (!query.success) {
      return res.status(400).json({
        error: 'Invalid status filter — expected pending, approved, rejected or all',
        details: query.error.issues,
      });
    }

    const { status } = query.data;

    const users = await prisma.user.findMany({
      where: status === 'all' ? APPLICANT_WHERE : { ...APPLICANT_WHERE, status },
      include: { profile: true },
      // Oldest first: the review queue is worked front to back, so whoever has
      // been waiting longest is seen first.
      orderBy: { createdAt: 'asc' },
    });

    res.status(200).json(users.map(serializeAdminApplicant));
  } catch (err) {
    next(err);
  }
}

async function getUserDetails(req, res, next) {
  try {
    const applicant = await findApplicant(req.params.id);
    if (applicant.error) {
      return res.status(applicant.status).json({ error: applicant.error });
    }

    res.status(200).json(serializeAdminApplicant(applicant.user));
  } catch (err) {
    next(err);
  }
}

async function approveUser(req, res, next) {
  try {
    const applicant = await findApplicant(req.params.id);
    if (applicant.error) {
      return res.status(applicant.status).json({ error: applicant.error });
    }

    // Idempotent, and doubles as the "reconsider a rejection" path: clearing
    // rejectionReason keeps a stale reason from surfacing on an approved user.
    const updated = await prisma.user.update({
      where: { id: applicant.user.id },
      data: {
        status: 'approved',
        rejectionReason: null,
        reviewedAt: new Date(),
        reviewedById: req.user.sub,
      },
      include: { profile: true },
    });

    res.status(200).json(serializeAdminApplicant(updated));
  } catch (err) {
    next(err);
  }
}

async function rejectUser(req, res, next) {
  try {
    const applicant = await findApplicant(req.params.id);
    if (applicant.error) {
      return res.status(applicant.status).json({ error: applicant.error });
    }

    const body = rejectBodySchema.safeParse(req.body ?? {});
    if (!body.success) {
      return res.status(400).json({ error: 'Invalid rejection reason', details: body.error.issues });
    }

    const updated = await prisma.user.update({
      where: { id: applicant.user.id },
      data: {
        status: 'rejected',
        rejectionReason: body.data.reason ?? null,
        reviewedAt: new Date(),
        reviewedById: req.user.sub,
      },
      include: { profile: true },
    });

    res.status(200).json(serializeAdminApplicant(updated));
  } catch (err) {
    next(err);
  }
}

// Resolves `:id` to an applicant, or to the response the caller should send.
// Admin ids 404 rather than 403 — an admin account simply isn't an applicant,
// and this endpoint has no other kind of resource to point at.
async function findApplicant(id) {
  const idResult = idParamSchema.safeParse(id);
  if (!idResult.success) {
    return { status: 400, error: 'Invalid user id' };
  }

  const user = await prisma.user.findFirst({
    where: { id: idResult.data, ...APPLICANT_WHERE },
    include: { profile: true },
  });

  if (!user) {
    return { status: 404, error: 'User not found' };
  }

  return { user };
}

module.exports = { getUsers, getUserDetails, approveUser, rejectUser };
