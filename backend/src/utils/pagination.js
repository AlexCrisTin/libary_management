const normalizePagination = (page, limit, { defaultLimit = 10, maxLimit = 100 } = {}) => {
    const normalizedPage = Math.max(1, Math.trunc(Number(page) || 1));
    const normalizedLimit = Math.min(
        maxLimit,
        Math.max(1, Math.trunc(Number(limit) || defaultLimit))
    );
    return {
        page: normalizedPage,
        limit: normalizedLimit,
        offset: (normalizedPage - 1) * normalizedLimit
    };
};

module.exports = { normalizePagination };
