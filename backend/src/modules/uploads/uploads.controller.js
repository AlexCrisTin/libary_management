const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const multer = require('multer');
const { sendSuccess, sendError } = require('../../utils/response');

const extensionByMime = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp'
};

const detectImageMime = (bytes) => {
    if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
        return 'image/jpeg';
    }
    if (bytes.length >= 8 && bytes.subarray(0, 8).equals(
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    )) {
        return 'image/png';
    }
    if (
        bytes.length >= 12 &&
        bytes.subarray(0, 4).toString('ascii') === 'RIFF' &&
        bytes.subarray(8, 12).toString('ascii') === 'WEBP'
    ) {
        return 'image/webp';
    }
    return null;
};

const removeUploadedFile = async (filePath) => {
    if (!filePath) return;
    await fs.promises.unlink(filePath).catch(() => {});
};

const validateImageBytes = async (file) => {
    const handle = await fs.promises.open(file.path, 'r');
    try {
        const bytes = Buffer.alloc(12);
        const { bytesRead } = await handle.read(bytes, 0, bytes.length, 0);
        return detectImageMime(bytes.subarray(0, bytesRead)) === file.mimetype;
    } finally {
        await handle.close();
    }
};

const createImageUpload = (folder, label) => {
    const uploadDirectory = path.join(__dirname, '../../../uploads', folder);
    fs.mkdirSync(uploadDirectory, { recursive: true });

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

    return (req, res) => upload(req, res, async (error) => {
        if (error) {
            const message = error.code === 'LIMIT_FILE_SIZE'
                ? `${label} không được vượt quá 5MB.`
                : error.message;
            return sendError(res, message, 400);
        }
        if (!req.file) {
            return sendError(res, 'Vui lòng chọn một file ảnh.', 400);
        }

        try {
            if (!await validateImageBytes(req.file)) {
                await removeUploadedFile(req.file.path);
                return sendError(res, 'Nội dung file không đúng định dạng ảnh JPG, PNG hoặc WebP.', 400);
            }
        } catch (_error) {
            await removeUploadedFile(req.file.path);
            return sendError(res, 'Không thể kiểm tra file ảnh đã tải lên.', 400);
        }

        return sendSuccess(res, `Tải ${label.toLowerCase()} thành công`, {
            url: `/uploads/${folder}/${req.file.filename}`,
            filename: req.file.filename,
            mime_type: req.file.mimetype,
            size: req.file.size
        }, 201);
    });
};

exports.uploadBookCover = createImageUpload('book-covers', 'Ảnh bìa');
exports.uploadReaderAvatar = createImageUpload('reader-avatars', 'Ảnh đại diện');
exports.uploadReportEvidence = createImageUpload('report-evidence', 'Ảnh minh chứng');
