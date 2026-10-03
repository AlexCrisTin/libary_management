const { SYSTEM_INSTRUCTION } = require('./ai.prompt');
const { functionDeclarations } = require('./ai.tools');

/**
 * Goi Gemini API qua REST ho tro Function Calling va Thought Signatures day du
 */
async function callGeminiApi({ contents, timeoutMs = null, retryCount = 1 }) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey === 'your_gemini_api_key_here') {
        throw new Error('Chưa cấu hình GEMINI_API_KEY trong file .env! Vui lòng thêm API Key để sử dụng tính năng AI.');
    }

    const modelName = process.env.GEMINI_MODEL || 'gemini-flash-latest';
    const ms = timeoutMs || parseInt(process.env.AI_TIMEOUT_MS, 10) || 30000;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

    const body = {
        contents,
        systemInstruction: {
            parts: [{ text: SYSTEM_INSTRUCTION }]
        },
        tools: [{ functionDeclarations }],
        generationConfig: {
            maxOutputTokens: parseInt(process.env.AI_MAX_OUTPUT_TOKENS, 10) || 1000,
            temperature: 0.2
        }
    };

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), ms);

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
            signal: controller.signal
        });

        clearTimeout(timer);

        if (!response.ok) {
            if (response.status === 503 && retryCount > 0) {
                console.log('[Gemini Provider] Gặp mã 503 (quá tải tạm thời), tự động thử lại sau 1.5 giây...');
                await new Promise(r => setTimeout(r, 1500));
                return callGeminiApi({ contents, timeoutMs, retryCount: retryCount - 1 });
            }

            const errData = await response.json().catch(() => ({}));
            const errMessage = errData.error?.message || response.statusText;
            if (response.status === 429) {
                throw new Error('Hạn mức sử dụng Gemini AI tạm thời đã hết hoặc bị giới hạn tần suất. Vui lòng thử lại sau ít phút!');
            }
            throw new Error(`[Gemini API Error ${response.status}]: ${errMessage}`);
        }

        const data = await response.json();
        return data;
    } catch (err) {
        clearTimeout(timer);
        if (err.name === 'AbortError') {
            throw new Error(`Yêu cầu đến Gemini đã quá thời gian phản hồi (${ms / 1000}s)! Vui lòng thử lại.`);
        }
        throw err;
    }
}

module.exports = {
    callGeminiApi
};
