function serializeUser(user) {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    status: user.status,
    rejectionReason: user.rejectionReason,
    createdAt: user.createdAt,
  };
}

function serializeProfile(profile) {
  return {
    name: profile.name,
    photoUrl: profile.photoUrl,
    designation: profile.designation,
    service: profile.service,
    department: profile.department,
    stateOrCadre: profile.stateOrCadre,
    yearsInService: profile.yearsInService,
    bio: profile.bio,
  };
}

function serializePublicProfile(userId, profile) {
  return {
    id: userId,
    profile: profile ? serializeProfile(profile) : null,
  };
}

// Admin-only view of an applicant. Unlike every other user-shaped response
// this one includes idCardPhotoUrl — reviewing that photo is the whole point
// of the approval screen — so it must never be reused on a non-admin route.
// Expects the user loaded with `include: { profile: true }`.
function serializeAdminApplicant(user) {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    status: user.status,
    idCardPhotoUrl: user.idCardPhotoUrl,
    rejectionReason: user.rejectionReason,
    reviewedAt: user.reviewedAt,
    reviewedById: user.reviewedById,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    profile: user.profile ? serializeProfile(user.profile) : null,
  };
}

module.exports = {
  serializeUser,
  serializeProfile,
  serializePublicProfile,
  serializeAdminApplicant,
};
