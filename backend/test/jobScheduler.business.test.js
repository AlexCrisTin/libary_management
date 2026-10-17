const test = require('node:test');
const assert = require('node:assert/strict');

const { createJobScheduler } = require('../src/jobs/jobScheduler');

const quietLogger = { log: () => {}, warn: () => {}, error: () => {} };

test('bộ lập lịch không cho một tác vụ chạy chồng lên chính nó', async () => {
    let releaseTask;
    let runCount = 0;
    const task = () => {
        runCount++;
        return new Promise((resolve) => {
            releaseTask = resolve;
        });
    };
    const scheduler = createJobScheduler({
        name: 'Test Scheduler',
        task,
        logger: quietLogger
    });

    const firstRun = scheduler.runNow();
    const secondRun = await scheduler.runNow();

    assert.equal(secondRun.skipped, true);
    assert.equal(secondRun.reason, 'already_running');
    assert.equal(runCount, 1);

    releaseTask({ ok: true });
    const firstResult = await firstRun;
    assert.deepEqual(firstResult.result, { ok: true });
    assert.equal(scheduler.getStatus().running, false);
});

test('không khởi động trùng bộ hẹn giờ và có thể dừng sạch', () => {
    const scheduler = createJobScheduler({
        name: 'Test Scheduler',
        task: async () => ({}),
        initialDelayMs: 60000,
        logger: quietLogger
    });

    assert.equal(scheduler.start(60), true);
    assert.equal(scheduler.start(60), false);
    assert.equal(scheduler.getStatus().started, true);
    assert.equal(scheduler.stop(), true);
    assert.equal(scheduler.getStatus().started, false);
});

test('từ chối chu kỳ chạy không hợp lệ', () => {
    const scheduler = createJobScheduler({
        name: 'Test Scheduler',
        task: async () => ({}),
        logger: quietLogger
    });

    assert.throws(() => scheduler.start(0), /lớn hơn 0/);
});
