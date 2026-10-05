const { SYSTEM_INSTRUCTION } = require('./ai.prompt');
const { functionDeclarations } = require('./ai.tools');

const OPENROUTER_ENDPOINT = 'https://openrouter.ai/api/v1/chat/completions';
const DEFAULT_MODEL = 'openrouter/free';

class OpenRouterApiError extends Error {
    constructor(message, statusCode, code) {
        super(message);
        this.name = 'OpenRouterApiError';
        this.statusCode = statusCode;
        this.code = code;
    }
}

function normalizeJsonSchema(value) {
    if (Array.isArray(value)) return value.map(normalizeJsonSchema);
    if (!value || typeof value !== 'object') return value;

    return Object.fromEntries(
        Object.entries(value).map(([key, item]) => {
            if (key === 'type' && typeof item === 'string') {
                return [key, item.toLowerCase()];
            }
            return [key, normalizeJsonSchema(item)];
        })
    );
}

const openRouterTools = functionDeclarations.map(declaration => ({
    type: 'function',
    function: {
        name: declaration.name,
        description: declaration.description,
        parameters: normalizeJsonSchema(declaration.parameters)
    }
}));

async function callOpenRouterApi({ messages, timeoutMs = null, retryCount = 1 }) {
    const apiKey = process.env.OPENROUTER_API_KEY;
    if (!apiKey || apiKey === 'your_openrouter_api_key_here') {
        throw new OpenRouterApiError(
            'Chưa cấu hình OPENROUTER_API_KEY trong file .env.',
            500,
            'OPENROUTER_KEY_MISSING'
        );
    }

    const modelName = process.env.OPENROUTER_MODEL || DEFAULT_MODEL;
    const ms = timeoutMs || parseInt(process.env.AI_TIMEOUT_MS, 10) || 30000;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), ms);

    try {
        const response = await fetch(OPENROUTER_ENDPOINT, {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
                'X-OpenRouter-Title': process.env.OPENROUTER_APP_NAME || 'Library Management AI'
            },
            body: JSON.stringify({
                model: modelName,
                messages: [
                    { role: 'system', content: SYSTEM_INSTRUCTION.trim() },
                    ...messages
                ],
                tools: openRouterTools,
                tool_choice: 'auto',
                parallel_tool_calls: false,
                temperature: 0.2,
                max_tokens: parseInt(process.env.AI_MAX_OUTPUT_TOKENS, 10) || 1000
            }),
            signal: controller.signal
        });

        clearTimeout(timer);

        if (!response.ok) {
            if ([502, 503, 504].includes(response.status) && retryCount > 0) {
                await new Promise(resolve => setTimeout(resolve, 1500));
                return callOpenRouterApi({
                    messages,
                    timeoutMs,
                    retryCount: retryCount - 1
                });
            }

            const errorData = await response.json().catch(() => ({}));
            const providerMessage = errorData.error?.message || response.statusText;

            if (response.status === 401) {
                throw new OpenRouterApiError(
                    'OpenRouter API key không hợp lệ hoặc đã bị thu hồi.',
                    401,
                    'OPENROUTER_INVALID_KEY'
                );
            }
            if (response.status === 402) {
                throw new OpenRouterApiError(
                    'Tài khoản OpenRouter không đủ credit để sử dụng model đã chọn. Hãy dùng model miễn phí hoặc nạp thêm credit.',
                    402,
                    'OPENROUTER_PAYMENT_REQUIRED'
                );
            }
            if (response.status === 429) {
                throw new OpenRouterApiError(
                    'OpenRouter đang giới hạn tần suất yêu cầu. Vui lòng thử lại sau ít phút.',
                    429,
                    'OPENROUTER_RATE_LIMITED'
                );
            }
            if (response.status === 404) {
                throw new OpenRouterApiError(
                    `Không tìm thấy model OpenRouter "${modelName}". Hãy kiểm tra OPENROUTER_MODEL trong file .env.`,
                    404,
                    'OPENROUTER_MODEL_NOT_FOUND'
                );
            }

            throw new OpenRouterApiError(
                `OpenRouter không thể xử lý yêu cầu: ${providerMessage}`,
                response.status,
                'OPENROUTER_API_ERROR'
            );
        }

        return response.json();
    } catch (error) {
        clearTimeout(timer);
        if (error.name === 'AbortError') {
            throw new OpenRouterApiError(
                `Yêu cầu đến OpenRouter đã quá thời gian phản hồi (${ms / 1000}s).`,
                504,
                'OPENROUTER_TIMEOUT'
            );
        }
        throw error;
    }
}

module.exports = {
    callOpenRouterApi,
    OpenRouterApiError,
    openRouterTools
};
