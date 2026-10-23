const crypto = require('crypto');

const LEGACY_JWT_SECRET = 'super_secret_library_jwt_key_2024';

const getJwtSecret = () => {
    const secret = (process.env.JWT_SECRET || '').trim();
    if (!secret || secret === LEGACY_JWT_SECRET || secret.length < 32) {
        const error = new Error(
            'JWT_SECRET phải được cấu hình riêng và có ít nhất 32 ký tự.'
        );
        error.code = 'INVALID_SECURITY_CONFIGURATION';
        throw error;
    }
    return secret;
};

const hashToken = (token) => crypto
    .createHash('sha256')
    .update(String(token || ''))
    .digest('hex');

const passwordVersion = (passwordHash) => crypto
    .createHash('sha256')
    .update(String(passwordHash || ''))
    .digest('hex')
    .slice(0, 24);

const generateOtp = () => crypto.randomInt(100000, 1000000).toString();

const hashOtp = (email, otp) => crypto
    .createHmac('sha256', getJwtSecret())
    .update(`${String(email).trim().toLowerCase()}:${String(otp).trim()}`)
    .digest('hex');

const verifyOtp = (email, otp, storedHash) => {
    const expected = Buffer.from(hashOtp(email, otp), 'hex');
    const actual = Buffer.from(String(storedHash || ''), 'hex');
    return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
};

const shouldExposeDevOtp = () => (
    process.env.NODE_ENV !== 'production' && process.env.DEV_OTP_ENABLED === 'true'
);

module.exports = {
    generateOtp,
    getJwtSecret,
    hashOtp,
    hashToken,
    passwordVersion,
    shouldExposeDevOtp,
    verifyOtp
};
