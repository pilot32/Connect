const multer = require('multer');

const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      const err = new Error('Only image uploads are allowed');
      err.status = 400;
      return cb(err);
    }
    cb(null, true);
  },
});

module.exports = upload;
