const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');
const { callGeminiApi } = require('./ai.provider');
const { toolsMap } = require('./ai.tools');

/**
 * 1. Gui cau hoi va dieu phoi vong lap goi Tool (Function Calling)
 */
async function chatWithLibrarianAI({ userId, userRole, message, conversation_id }) {
    let currentConversationId = conversation_id;

    // 1. Kiem tra hoac tao phien hoi thoai moi
    if (currentConversationId) {
        const [convRows] = await db.query(
            'SELECT * FROM ai_conversations WHERE conversation_id = ?',
            [currentConversationId]
        );
        if (convRows.length === 0) {
            throw new Error('Không tìm thấy phiên hội thoại này!');
        }
        const conv = convRows[0];
        // Thu thu chi duoc chat trong phien cua minh, Admin duoc quyen toan bo
        if (userRole !== 'admin' && conv.user_id !== userId) {
            throw new Error('Bạn không có quyền truy cập vào phiên hội thoại này!');
        }
    } else {
        currentConversationId = uuidv4();
        const autoTitle = message.length > 60 ? `${message.substring(0, 57)}...` : message;
        await db.query(
            'INSERT INTO ai_conversations (conversation_id, user_id, title, created_at) VALUES (?, ?, ?, NOW())',
            [currentConversationId, userId, autoTitle]
        );
    }

    // 2. Lay lich su tin nhan gan nhat (toi da 6 tin) de lam ngu canh
    const [historyRows] = await db.query(
        `SELECT role, content 
         FROM ai_messages 
         WHERE conversation_id = ? AND role IN ('user', 'model')
         ORDER BY created_at ASC 
         LIMIT 6`,
        [currentConversationId]
    );

    // Chuyen doi lich su sang cau truc contents
    const contents = historyRows.map(r => ({
        role: r.role === 'user' ? 'user' : 'model',
        parts: [{ text: r.content }]
    }));

    // Them cau hoi hien tai cua thu thu
    contents.push({
        role: 'user',
        parts: [{ text: message }]
    });

    const startTime = Date.now();
    const toolsCalled = [];
    const sources = [];
    let finalAnswer = '';

    try {
        let loopCount = 0;
        const maxLoops = 4;

        while (loopCount < maxLoops) {
            const apiResult = await callGeminiApi({ contents });
            const candidate = apiResult.candidates?.[0];
            if (!candidate || !candidate.content) {
                throw new Error('Không nhận được phản hồi hợp lệ từ Gemini.');
            }

            // Luu candidate vao lich su vong hoi thoai hien tai
            contents.push(candidate.content);

            // Kiem tra xem Gemini co yeu cau goi function hay khong
            const callParts = candidate.content.parts.filter(p => p.functionCall);
            if (!callParts || callParts.length === 0) {
                // Khong con goi tool nua, trich xuat cau tra loi bang van ban cuoi cung
                finalAnswer = candidate.content.parts
                    .map(p => p.text)
                    .filter(Boolean)
                    .join('\n')
                    .trim();
                break;
            }

            loopCount++;
            const responseParts = [];

            for (const part of callParts) {
                const call = part.functionCall;
                const toolName = call.name;
                const toolArgs = call.args || {};
                toolsCalled.push(toolName);

                let toolOutput = {};
                const toolFn = toolsMap[toolName];

                if (typeof toolFn === 'function') {
                    try {
                        toolOutput = await toolFn(toolArgs);
                    } catch (toolErr) {
                        toolOutput = { error: toolErr.message };
                    }
                } else {
                    toolOutput = { error: `Công cụ ${toolName} chưa được hỗ trợ.` };
                }

                // Trich xuat metadata nguon tra cuu
                if (toolOutput.loans && Array.isArray(toolOutput.loans)) {
                    toolOutput.loans.forEach(loan => {
                        if (loan.tx_id) {
                            sources.push({ type: 'borrow_transaction', id: loan.tx_id, label: loan.book_title });
                        }
                    });
                }
                if (toolOutput.books && Array.isArray(toolOutput.books)) {
                    toolOutput.books.forEach(b => {
                        if (b.bib_id) {
                            sources.push({ type: 'book', id: b.bib_id, label: b.title });
                        }
                    });
                }

                responseParts.push({
                    functionResponse: {
                        name: toolName,
                        response: toolOutput
                    }
                });
            }

            // Dua ket qua thuc thi tool vao voi role: 'user'
            contents.push({
                role: 'user',
                parts: responseParts
            });
        }

        if (!finalAnswer) {
            finalAnswer = 'Tôi đã tra cứu dữ liệu nhưng không thể tạo câu trả lời hoàn chỉnh. Vui lòng thử lại với câu hỏi cụ thể hơn.';
        }

        const responseTimeMs = Date.now() - startTime;

        // 4. Luu tin nhan cua user va phan hoi cua AI vao co so du lieu
        const userMsgId = uuidv4();
        await db.query(
            'INSERT INTO ai_messages (message_id, conversation_id, role, content, created_at) VALUES (?, ?, "user", ?, NOW())',
            [userMsgId, currentConversationId, message]
        );

        const modelMsgId = uuidv4();
        const sourcesJson = sources.length > 0 ? JSON.stringify(sources) : null;
        const toolsCalledStr = toolsCalled.join(', ') || null;

        await db.query(
            `INSERT INTO ai_messages (message_id, conversation_id, role, content, tool_name, sources, created_at) 
             VALUES (?, ?, "model", ?, ?, ?, NOW())`,
            [modelMsgId, currentConversationId, finalAnswer, toolsCalledStr, sourcesJson]
        );

        // 5. Ghi log giam sat vao bang ai_usage_logs
        await logUsage({
            userId,
            conversationId: currentConversationId,
            modelName: process.env.GEMINI_MODEL || 'gemini-flash-latest',
            toolsCalled: toolsCalledStr,
            responseTimeMs,
            status: 'success'
        });

        return {
            answer: finalAnswer,
            conversation_id: currentConversationId,
            sources
        };
    } catch (err) {
        await logUsage({
            userId,
            conversationId: currentConversationId,
            modelName: process.env.GEMINI_MODEL || 'gemini-flash-latest',
            toolsCalled: toolsCalled.join(', ') || null,
            responseTimeMs: Date.now() - startTime,
            status: err.message.includes('quá thời gian') ? 'timeout' : 'failed',
            errorMessage: err.message
        });
        throw err;
    }
}

/**
 * Helper ghi log su dung AI
 */
async function logUsage({ userId, conversationId, modelName, toolsCalled, responseTimeMs, status, errorMessage = null }) {
    try {
        const logId = uuidv4();
        await db.query(
            `INSERT INTO ai_usage_logs (
                log_id, user_id, conversation_id, model, tools_called, response_time_ms, status, error_message, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
            [logId, userId, conversationId, modelName, toolsCalled, responseTimeMs, status, errorMessage]
        );
    } catch (logErr) {
        console.error('[AI Log Error]:', logErr.message);
    }
}

/**
 * 2. Lay danh sach cac cuoc hoi thoai cua Thu thu
 */
async function getConversations({ userId, userRole, page = 1, limit = 10 }) {
    const offset = (page - 1) * limit;
    let whereClause = 'WHERE c.user_id = ?';
    const params = [userId];

    if (userRole === 'admin') {
        whereClause = '';
        params.pop();
    }

    const countSql = `SELECT COUNT(*) AS total FROM ai_conversations c ${whereClause}`;
    const [countRows] = await db.query(countSql, params);
    const total = countRows[0].total;

    const sql = `
        SELECT 
            c.conversation_id,
            c.user_id,
            c.title,
            c.created_at,
            c.updated_at,
            u.full_name AS created_by
        FROM ai_conversations c
        JOIN users u ON c.user_id = u.user_id
        ${whereClause}
        ORDER BY c.updated_at DESC
        LIMIT ? OFFSET ?
    `;

    const [rows] = await db.query(sql, [...params, Number(limit), Number(offset)]);

    return {
        total,
        page,
        limit,
        total_pages: Math.ceil(total / limit),
        conversations: rows
    };
}

/**
 * 3. Lay chi tiet tin nhan trong 1 cuoc hoi thoai
 */
async function getConversationDetail({ conversationId, userId, userRole }) {
    const [convRows] = await db.query(
        'SELECT * FROM ai_conversations WHERE conversation_id = ?',
        [conversationId]
    );

    if (convRows.length === 0) {
        throw new Error('Không tìm thấy cuộc trò chuyện này!');
    }

    const conv = convRows[0];
    if (userRole !== 'admin' && conv.user_id !== userId) {
        throw new Error('Bạn không có quyền xem cuộc trò chuyện này!');
    }

    const [messages] = await db.query(
        `SELECT message_id, role, content, tool_name, sources, created_at 
         FROM ai_messages 
         WHERE conversation_id = ? 
         ORDER BY created_at ASC`,
        [conversationId]
    );

    return {
        conversation: conv,
        messages: messages.map(m => ({
            ...m,
            sources: m.sources ? JSON.parse(m.sources) : []
        }))
    };
}

/**
 * 4. Xoa 1 cuoc hoi thoai
 */
async function deleteConversation({ conversationId, userId, userRole }) {
    const [convRows] = await db.query(
        'SELECT * FROM ai_conversations WHERE conversation_id = ?',
        [conversationId]
    );

    if (convRows.length === 0) {
        throw new Error('Không tìm thấy cuộc trò chuyện để xóa!');
    }

    const conv = convRows[0];
    if (userRole !== 'admin' && conv.user_id !== userId) {
        throw new Error('Bạn không có quyền xóa cuộc trò chuyện này!');
    }

    await db.query('DELETE FROM ai_conversations WHERE conversation_id = ?', [conversationId]);

    return {
        message: 'Đã xóa cuộc trò chuyện thành công'
    };
}

module.exports = {
    chatWithLibrarianAI,
    getConversations,
    getConversationDetail,
    deleteConversation
};
