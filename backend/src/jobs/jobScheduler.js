/**
 * Bộ lập lịch nhẹ cho các nghiệp vụ chạy nền.
 * - Không cho cùng một tác vụ chạy chồng lên chính nó.
 * - Chặn việc khởi động nhiều bộ hẹn giờ cho cùng tác vụ.
 * - Lưu trạng thái lần chạy gần nhất để thuận tiện theo dõi/log.
 */
function createJobScheduler({
    name,
    task,
    initialDelayMs = 0,
    onSuccess = null,
    logger = console
}) {
    let startupTimer = null;
    let intervalTimer = null;
    let running = false;
    let lastStartedAt = null;
    let lastFinishedAt = null;
    let lastError = null;

    const runNow = async () => {
        if (running) {
            logger.warn(`[${name}] Bỏ qua lượt chạy vì tác vụ trước vẫn chưa hoàn tất.`);
            return { skipped: true, reason: 'already_running' };
        }

        running = true;
        lastStartedAt = new Date();
        lastError = null;
        try {
            const result = await task();
            if (onSuccess) onSuccess(result);
            return { skipped: false, result };
        } catch (error) {
            lastError = error?.message || String(error);
            logger.error(`[${name}] Lỗi: ${lastError}`);
            return { skipped: false, error };
        } finally {
            running = false;
            lastFinishedAt = new Date();
        }
    };

    const start = (intervalMinutes) => {
        const normalizedInterval = Number(intervalMinutes);
        if (!Number.isFinite(normalizedInterval) || normalizedInterval <= 0) {
            throw new Error(`[${name}] Chu kỳ chạy phải là số phút lớn hơn 0.`);
        }
        if (startupTimer || intervalTimer) {
            logger.warn(`[${name}] Bộ lập lịch đã chạy, không khởi động thêm.`);
            return false;
        }

        logger.log(`[${name}] Khởi động, chu kỳ ${normalizedInterval} phút/lần.`);
        startupTimer = setTimeout(() => {
            startupTimer = null;
            void runNow();
        }, Math.max(0, initialDelayMs));
        intervalTimer = setInterval(
            () => void runNow(),
            normalizedInterval * 60 * 1000
        );
        return true;
    };

    const stop = () => {
        if (startupTimer) clearTimeout(startupTimer);
        if (intervalTimer) clearInterval(intervalTimer);
        const wasStarted = Boolean(startupTimer || intervalTimer);
        startupTimer = null;
        intervalTimer = null;
        if (wasStarted) logger.log(`[${name}] Đã dừng.`);
        return wasStarted;
    };

    const getStatus = () => ({
        name,
        started: Boolean(startupTimer || intervalTimer),
        running,
        last_started_at: lastStartedAt,
        last_finished_at: lastFinishedAt,
        last_error: lastError
    });

    return { start, stop, runNow, getStatus };
}

module.exports = { createJobScheduler };
