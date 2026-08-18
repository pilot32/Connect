const prisma = require('../config/db');

/**
 * Gates admin-only routes. Chain it after `requireAuth`, which has already
 * verified the JWT and populated `req.user`.
 *
 * The role is re-read from the database rather than trusted from the token:
 * tokens live for 7 days, so an admin demoted today would otherwise keep
 * admin access until their token expired.
 */
async function requireAdmin(req, res, next) {
  try {
    const account = await prisma.user.findUnique({
      where: { id: req.user.sub },
      select: { id: true, email: true, role: true, status: true },
    });

    if (!account) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    if (account.role !== 'admin') {
      return res.status(403).json({ error: 'Admin access required', code: 'ADMIN_ONLY' });
    }

    req.user = { ...req.user, role: account.role, status: account.status };
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { requireAdmin };
