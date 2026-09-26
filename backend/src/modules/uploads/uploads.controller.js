const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const multer = require('multer');
const { sendSuccess, sendError } = require('../../utils/response');

const uploadDirectory = path.join(__dirname, '../../../uploads/book-covers');
fs.mkdirSync(uploadDirectory, { recursive: true });

const extensionByMime = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp'
};

const storage = multer.diskStorage({
    destination: (_req, _file, callback) => callback(null, uploadDirectory),
    filename: (_req, file, callback) => {
        const extension = extensionByMime[file.mimetype] || '.jpg';
        callback(null, `${randomUUID()}${extension}`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
        if (!extensionByMime[file.mimetype]) {
            return callback(new Error('Chỉ chấp nhận ảnh JPG, PNG hoặc WebP.'));
        }
        callback(null, true);
    }
}).single('file');

exports.uploadBookCover = (req, res) => {
    upload(req, res, (error) => {
        if (error) {
            const message = error.code === 'LIMIT_FILE_SIZE'
                ? 'Ảnh bìa không được vượt quá 5MB.'
                : error.message;
            return sendError(res, message, 400);
        }
        if (!req.file) {
            return sendError(res, 'Vui lòng chọn một file ảnh.', 400);
        }

        return sendSuccess(res, 'Tải ảnh bìa thành công', {
            url: `/uploads/book-covers/${req.file.filename}`,
            filename: req.file.filename,
            mime_type: req.file.mimetype,
            size: req.file.size
        }, 201);
    });
};
