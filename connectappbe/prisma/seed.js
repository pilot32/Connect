/**
 * Seeds the initial admin account. Idempotent — re-running it updates the
 * existing admin's password rather than failing on the unique email.
 *
 *   node prisma/seed.js
 *
 * Credentials come from ADMIN_EMAIL / ADMIN_PASSWORD when set, so production
 * never has to ship with the development default.
 */
require('dotenv').config();

const prisma = require('../src/config/db');
const { hashPassword } = require('../src/utils/password');

const adminEmail = process.env.ADMIN_EMAIL || 'admin@govconnect.in';
const adminPassword = process.env.ADMIN_PASSWORD || 'admin@12345';

async function main() {
  if (adminPassword.length < 8) {
    throw new Error('ADMIN_PASSWORD must be at least 8 characters');
  }

  const passwordHash = await hashPassword(adminPassword);

  const admin = await prisma.user.upsert({
    where: { email: adminEmail },
    // An admin needs no review of its own — seed it straight to approved so
    // requireApproved never has to special-case a pending admin.
    update: { passwordHash, role: 'admin', status: 'approved' },
    create: { email: adminEmail, passwordHash, role: 'admin', status: 'approved' },
  });

  console.log(`Seeded admin ${admin.email} (${admin.id})`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
