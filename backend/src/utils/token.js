const jwt = require("jsonwebtoken");
const env = require("../config/env");

const generateAccessToken = (payload) =>
  jwt.sign(payload, env.JWT_ACCESS_SECRET, { expiresIn: env.JWT_ACCESS_EXPIRES_IN });

const generateRefreshToken = (payload) =>
  jwt.sign(payload, env.JWT_REFRESH_SECRET, { expiresIn: env.JWT_REFRESH_EXPIRES_IN });

module.exports = {
  generateAccessToken,
  generateRefreshToken,
};
