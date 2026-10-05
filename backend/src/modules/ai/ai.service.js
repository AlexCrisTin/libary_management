const db = require('../../config/db');
const { v4: uuidv4 } = require('uuid');
const { callOpenRouterApi } = require('./ai.provider');
const { toolsMap } = require('./ai.tools');

/**
 * 1. Gui cau hoi va dieu phoi vong lap goi Tool (Function Calling)
 */
async function chatWithLibrarianAI({ userId, userRole, message, conversation_id }) {
    let currentConversationId = conversation_id;
    let createdNewConversation = false;

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
        createdNewConversation = true;
        const autoTitle = message.length > 60 ? `${message.substring(0, 57)}...` : message;
        await db.query(
            'INSERT INTO ai_conversations (conversation_id, user_id, title, created_at) VALUES (?, ?, ?, NOW())',
            [currentConversationId, userId, autoTitle]
        );
    }

    // 2. Lay lich su tin nhan gan nhat (toi da 6 tin) de lam ngu canh
    const [historyRows] = await db.query(
        `SELECT role, content
         FROM (
             SELECT message_id, role, content, created_at
             FROM ai_messages
             WHERE conversation_id = ? AND role IN ('user', 'model')
             ORDER BY created_at DESC, message_id DESC
             LIMIT 6
         ) recent_messages
         ORDER BY created_at ASC, message_id ASC`,
        [currentConversationId]
    );

    // Chuyen lich su sang dinh dang Chat Completions cua OpenRouter
    const messages = historyRows.map(r => ({
        role: r.role === 'user' ? 'user' : 'assistant',
        content: r.content
    }));

    // Them cau hoi hien tai cua thu thu
    messages.push({
        role: 'user',
        content: message
    });

    const startTime = Date.now();
    const toolsCalled = [];
    const sources = [];
    let finalAnswer = '';
    let usedModel = process.env.OPENROUTER_MODEL || 'openrouter/free';

    try {
        let loopCount = 0;
        const maxLoops = 4;

        while (loopCount < maxLoops) {
            const apiResult = await callOpenRouterApi({ messages });
            usedModel = apiResult.model || usedModel;
            const assistantMessage = apiResult.choices?.[0]?.message;
            if (!assistantMessage) {
                throw new Error('Không nhận được phản hồi hợp lệ từ OpenRouter.');
            }

            // OpenRouter can nhan lai chinh assistant message de giu ngu canh tool call
            messages.push({
                role: 'assistant',
                content: assistantMessage.content || '',
                ...(Array.isArray(assistantMessage.tool_calls)
                    ? { tool_calls: assistantMessage.tool_calls }
                    : {})
            });

            const toolCalls = Array.isArray(assistantMessage.tool_calls)
                ? assistantMessage.tool_calls
                : [];
            if (toolCalls.length === 0) {
                finalAnswer = String(assistantMessage.content || '').trim();
                break;
            }

            loopCount++;

            for (const call of toolCalls) {
                const toolName = call.function?.name;
                let toolArgs = {};
                const rawArguments = call.function?.arguments;
                if (rawArguments && typeof rawArguments === 'object') {
                    toolArgs = rawArguments;
                } else {
                    try {
                        toolArgs = JSON.parse(rawArguments || '{}');
                    } catch {
                        toolArgs = {};
                    }
                }
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

                messages.push({
                    role: 'tool',
                    tool_call_id: call.id,
                    name: toolName,
                    content: JSON.stringify(toolOutput)
                });
            }
        }

        if (!finalAnswer) {
            finalAnswer = 'Tôi đã tra cứu dữ liệu nhưng không thể tạo câu trả lời hoàn chỉnh. Vui lòng thử lại với câu hỏi cụ thể hơn.';
        }

        const responseTimeMs = Date.now() - startTime;

        // 4. Luu tin nhan cua user va phan hoi cua AI vao co so du lieu
        const userMsgId = uuidv4();
        const modelMsgId = uuidv4();
        const sourcesJson = sources.length > 0 ? JSON.stringify(sources) : null;
        const toolsCalledStr = toolsCalled.join(', ') || null;
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();
            await connection.query(
                'INSERT INTO ai_messages (message_id, conversation_id, role, content, created_at) VALUES (?, ?, "user", ?, NOW())',
                [userMsgId, currentConversationId, message]
            );
            await connection.query(
                `INSERT INTO ai_messages (message_id, conversation_id, role, content, tool_name, sources, created_at)
                 VALUES (?, ?, "model", ?, ?, ?, NOW())`,
                [modelMsgId, currentConversationId, finalAnswer, toolsCalledStr, sourcesJson]
            );
            await connection.query(
                'UPDATE ai_conversations SET updated_at = NOW() WHERE conversation_id = ?',
                [currentConversationId]
            );
            await connection.commit();
        } catch (saveError) {
            await connection.rollback();
            throw saveError;
        } finally {
            connection.release();
        }

        // 5. Ghi log giam sat vao bang ai_usage_logs
        await logUsage({
            userId,
            conversationId: currentConversationId,
            modelName: usedModel,
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
            modelName: usedModel,
            toolsCalled: toolsCalled.join(', ') || null,
            responseTimeMs: Date.now() - startTime,
            status: err.code === 'OPENROUTER_TIMEOUT' ? 'timeout' : 'failed',
            errorMessage: err.message
        });
        if (createdNewConversation) {
            await db.query(
                'DELETE FROM ai_conversations WHERE conversation_id = ?',
                [currentConversationId]
            ).catch(cleanupError => {
                console.error('[AI Conversation Cleanup Error]:', cleanupError.message);
            });
        }
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
        messages: messages.map(m => {
            let sources = [];
            if (Array.isArray(m.sources)) {
                sources = m.sources;
            } else if (m.sources && typeof m.sources === 'object') {
                sources = m.sources;
            } else if (m.sources) {
                try {
                    sources = JSON.parse(m.sources);
                } catch {
                    sources = [];
                }
            }
            return { ...m, sources };
        })
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
