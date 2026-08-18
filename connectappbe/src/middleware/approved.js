const prisma = require('../config/db');

/**
 * Blocks app features until an account has been approved by an admin. Chain it
 * after `requireAuth`.
 *
 * Status is re-read from the database on every request instead of being taken
 * from the JWT: a user who signs up gets a token stamped `pending`, and that
 * token is valid for 7 days. Reading the token would keep them locked out long
 * after an admin approved them, forcing a re-login. Reading the row means
 * approval takes effect on their very next request.
 */
async function requireApproved(req, res, next) {
  try {
    const account = await prisma.user.findUnique({
      where: { id: req.user.sub },
      select: { id: true, role: true, status: true, rejectionReason: true },
    });

    if (!account) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = { ...req.user, role: account.role, status: account.status };

    // Admins are reviewers, not applicants — they are never gated.
    if (account.role === 'admin') {
      return next();
    }

    if (account.status === 'approved') {
      return next();
    }

    if (account.status === 'rejected') {
      return res.status(403).json({
        error: 'Your account was not approved',
        code: 'ACCOUNT_REJECTED',
        rejectionReason: account.rejectionReason,
      });
    }

    return res.status(403).json({
      error: 'Your account is awaiting admin approval',
      code: 'ACCOUNT_PENDING',
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { requireApproved };
