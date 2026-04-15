const jwt = require("jsonwebtoken");

const User = require("../models/user.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");
const { generateAccessToken, generateRefreshToken } = require("../utils/token");
const env = require("../config/env");

const buildAuthPayload = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
});

const issueTokens = async (user) => {
  const tokenPayload = { userId: user._id, role: user.role };
  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  user.refreshToken = refreshToken;
  await user.save();

  return { accessToken, refreshToken };
};

const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    throw new ApiError(400, "Name, email and password are required");
  }

  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) {
    throw new ApiError(409, "User already exists with this email");
  }

  const user = await User.create({ name, email: email.toLowerCase(), password });
  const tokens = await issueTokens(user);

  return res
    .status(201)
    .json(new ApiResponse(201, "User registered successfully", { user: buildAuthPayload(user), ...tokens }));
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    throw new ApiError(400, "Email and password are required");
  }

  const user = await User.findOne({ email: email.toLowerCase() }).select("+password +refreshToken");
  if (!user) {
    throw new ApiError(401, "Invalid credentials");
  }

  const isPasswordValid = await user.comparePassword(password);
  if (!isPasswordValid) {
    throw new ApiError(401, "Invalid credentials");
  }

  const tokens = await issueTokens(user);

  return res
    .status(200)
    .json(new ApiResponse(200, "Login successful", { user: buildAuthPayload(user), ...tokens }));
});

const refreshAccessToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new ApiError(400, "Refresh token is required");
  }

  const decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
  const user = await User.findById(decoded.userId).select("+refreshToken");

  if (!user || user.refreshToken !== refreshToken) {
    throw new ApiError(401, "Invalid refresh token");
  }

  const accessToken = generateAccessToken({ userId: user._id, role: user.role });

  return res.status(200).json(new ApiResponse(200, "Token refreshed", { accessToken }));
});

const logout = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select("+refreshToken");
  if (user) {
    user.refreshToken = undefined;
    await user.save();
  }

  return res.status(200).json(new ApiResponse(200, "Logged out successfully"));
});

module.exports = {
  register,
  login,
  refreshAccessToken,
  logout,
};
