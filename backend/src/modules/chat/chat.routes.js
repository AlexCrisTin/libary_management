const express = require('express');
const router = express.Router();
const chatController = require('./chat.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');

// Tất cả thao tác chat đều yêu cầu đăng nhập
router.use(authMiddleware);

// 1. Gửi tin nhắn mới (Độc giả hoặc Thủ thư)
router.post('/messages', chatController.sendMessage);

// 2. Độc giả tải lịch sử trò chuyện của chính mình
router.get('/messages', chatController.getReaderMessages);

// 3. Thủ thư xem danh sách tất cả các cuộc hội thoại
router.get('/conversations', roleMiddleware('librarian', 'admin'), chatController.getConversations);

// 4. Thủ thư xem chi tiết tin nhắn với một độc giả cụ thể
router.get('/conversations/:readerId/messages', roleMiddleware('librarian', 'admin'), chatController.getConversationDetail);

module.exports = router;
