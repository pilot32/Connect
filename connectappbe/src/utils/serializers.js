function serializeUser(user) {
  return { id: user.id, email: user.email };
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

module.exports = { serializeUser, serializeProfile, serializePublicProfile };
