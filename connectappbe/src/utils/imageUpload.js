const cloudinary = require('../config/cloudinary');

async function uploadImageBuffer(buffer, mimetype, folder) {
  const dataUri = `data:${mimetype};base64,${buffer.toString('base64')}`;
  const result = await cloudinary.uploader.upload(dataUri, { folder });
  return result.secure_url;
}

module.exports = { uploadImageBuffer };
