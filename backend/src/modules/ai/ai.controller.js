const aiService = require('./ai.service');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * 1. POST /api/ai/librarian/chat - Gui cau hoi cho Tro ly AI Thu thu
 */
exports.chat = async (req, res, next) => {
    try {
        const { message, conversation_id } = req.body;

        if (!message || typeof message !== 'string' || !message.trim()) {
            return sendError(res, 'Vui lòng cung cấp nội dung câu hỏi (message)!', 400);
        }

        if (message.length > 1000) {
            return sendError(res, 'Độ dài câu hỏi vượt quá giới hạn cho phép (tối đa 1000 ký tự)!', 400);
        }

        const result = await aiService.chatWithLibrarianAI({
            userId: req.user.userId,
            userRole: req.user.role,
            message: message.trim(),
            conversation_id: conversation_id || null
        });

        return sendSuccess(res, 'Phản hồi từ Trợ lý AI thành công', result);
    } catch (error) {
        console.error('[AI Chat Error]:', error.message);

        // Xu ly rieng cac loi lien quan den Gemini Quota hoac API Key
        if (error.message.includes('429') || error.message.includes('quota') || error.message.includes('ResourceExhausted')) {
            return sendError(res, 'Hạn mức sử dụng Gemini AI tạm thời đã hết hoặc bị giới hạn tần suất. Vui lòng thử lại sau ít phút!', 429);
        }

        if (error.message.includes('GEMINI_API_KEY')) {
            return sendError(res, error.message, 500);
        }

        return sendError(res, error.message || 'Lỗi xử lý Trợ lý AI', 400);
    }
};

/**
 * 2. GET /api/ai/librarian/conversations - Lay danh sach cuoc hoi thoai
 */
exports.getConversations = async (req, res, next) => {
    try {
        const { page, limit } = req.query;
        const result = await aiService.getConversations({
            userId: req.user.userId,
            userRole: req.user.role,
            page: parseInt(page || 1, 10),
            limit: parseInt(limit || 10, 10)
        });

        return sendSuccess(res, 'Lấy danh sách cuộc trò chuyện thành công', result);
    } catch (error) {
        next(error);
    }
};

/**
 * 3. GET /api/ai/librarian/conversations/:id - Lay chi tiet tin nhan
 */
exports.getConversationDetail = async (req, res, next) => {
    try {
        const conversationId = req.params.id;
        const result = await aiService.getConversationDetail({
            conversationId,
            userId: req.user.userId,
            userRole: req.user.role
        });

        return sendSuccess(res, 'Lấy chi tiết cuộc trò chuyện thành công', result);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};

/**
 * 4. DELETE /api/ai/librarian/conversations/:id - Xoa cuoc hoi thoai
 */
exports.deleteConversation = async (req, res, next) => {
    try {
        const conversationId = req.params.id;
        const result = await aiService.deleteConversation({
            conversationId,
            userId: req.user.userId,
            userRole: req.user.role
        });

        return sendSuccess(res, result.message);
    } catch (error) {
        return sendError(res, error.message, 400);
    }
};
