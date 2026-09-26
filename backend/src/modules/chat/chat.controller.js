const chatService = require('./chat.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/chat/messages - Gửi tin nhắn mới
 */
exports.sendMessage = async (req, res, next) => {
    try {
        const { message_text } = req.body;
        const sender_id = req.user.userId;
        const user_role = req.user.role;

        let reader_id;
        let sender_role;

        if (user_role === 'reader') {
            reader_id = req.user.readerId;
            sender_role = 'reader';
            if (!reader_id) {
                return sendError(res, 'Tài khoản độc giả này chưa liên kết với thẻ thư viện!', 403);
            }
        } else {
            // Thủ thư hoặc Admin gửi tin nhắn cho độc giả
            reader_id = req.body.reader_id;
            sender_role = 'librarian';
            if (!reader_id) {
                return sendError(res, 'Vui lòng cung cấp mã ID của độc giả muốn gửi tin nhắn (reader_id)!', 400);
            }
        }

        const result = await chatService.sendMessage({
            reader_id,
            sender_id,
            sender_role,
            message_text
        });

        return sendSuccess(res, 'Gửi tin nhắn thành công', result, 201);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 2. GET /api/chat/messages - Độc giả tải lịch sử trò chuyện của mình
 */
exports.getReaderMessages = async (req, res, next) => {
    try {
        const reader_id = req.user.readerId;
        if (!reader_id) {
            return sendError(res, 'Chức năng này chỉ dành cho độc giả!', 403);
        }

        const { page, limit } = req.query;
        const result = await chatService.getMessages({
            reader_id,
            viewer_role: 'reader',
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 50, 10)
        });

        return sendSuccess(res, 'Lấy lịch sử tin nhắn thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. GET /api/chat/conversations - Thủ thư xem danh sách các cuộc trò chuyện
 */
exports.getConversations = async (req, res, next) => {
    try {
        const { page, limit } = req.query;
        const result = await chatService.getConversations({
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 20, 10)
        });

        return sendSuccess(res, 'Lấy danh sách các cuộc hội thoại thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 4. GET /api/chat/conversations/:readerId/messages - Thủ thư tải lịch sử chat với 1 độc giả
 */
exports.getConversationDetail = async (req, res, next) => {
    try {
        const reader_id = req.params.readerId;
        const { page, limit } = req.query;

        const result = await chatService.getMessages({
            reader_id,
            viewer_role: req.user.role,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 50, 10)
        });

        return sendSuccess(res, 'Lấy chi tiết cuộc hội thoại thành công', result);
    } catch (error) {
        next(error);
    }
};
