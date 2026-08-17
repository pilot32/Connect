const prisma = require('../config/db');
const { serializePublicProfile } = require('../utils/serializers');

function containsFilter(value) {
  return { contains: value, mode: 'insensitive' };
}

async function search(req, res, next) {
  try {
    const { service, department, state } = req.query;

    // Only approved officials are browsable — listing a pending or rejected
    // applicant here would hand them the visibility that approval is meant to
    // grant, even though requireApproved keeps them from browsing themselves.
    const where = { user: { status: 'approved' } };
    if (typeof service === 'string' && service.trim()) where.service = containsFilter(service);
    if (typeof department === 'string' && department.trim()) where.department = containsFilter(department);
    if (typeof state === 'string' && state.trim()) where.stateOrCadre = containsFilter(state);

    const profiles = await prisma.profile.findMany({
      where,
      orderBy: { name: 'asc' },
    });

    res.status(200).json(profiles.map((profile) => serializePublicProfile(profile.userId, profile)));
  } catch (err) {
    next(err);
  }
}

module.exports = { search };
