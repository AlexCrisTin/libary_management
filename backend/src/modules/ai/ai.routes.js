const express = require('express');
const router = express.Router();
const aiController = require('./ai.controller');
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const { aiLimiter } = require('../../middlewares/rateLimiter.middleware');

// Toàn bộ các API AI dành riêng cho Thủ thư bắt buộc phải đăng nhập và có role là 'librarian' hoặc 'admin'
router.use(authMiddleware);
router.use(roleMiddleware('librarian', 'admin'));

// 1. Gửi tin nhắn chat với Trợ lý AI Thủ thư (có Function Calling tra cứu dữ liệu thư viện)
router.post('/librarian/chat', aiLimiter, aiController.chat);

// 2. Lấy danh sách các cuộc hội thoại của thủ thư
router.get('/librarian/conversations', aiController.getConversations);

// 3. Lấy chi tiết lịch sử tin nhắn trong một cuộc trò chuyện
router.get('/librarian/conversations/:id', aiController.getConversationDetail);

// 4. Xóa một cuộc trò chuyện
router.delete('/librarian/conversations/:id', aiController.deleteConversation);

module.exports = router;
