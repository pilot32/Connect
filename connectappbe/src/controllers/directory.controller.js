const prisma = require('../config/db');
const { serializePublicProfile } = require('../utils/serializers');

function containsFilter(value) {
  return { contains: value, mode: 'insensitive' };
}

async function search(req, res, next) {
  try {
    const { service, department, state } = req.query;

    const where = {};
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
