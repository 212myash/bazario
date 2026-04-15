const jwt = require("jsonwebtoken");
const env = require("../config/env");
const User = require("../models/user.model");
const ApiError = require("../utils/ApiError");
const { ROLES } = require("../constants/roles");

const protect = async (req, _res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next(new ApiError(401, "Unauthorized: Missing token"));
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET);
    const user = await User.findById(decoded.userId).select("-password");

    if (!user) {
      return next(new ApiError(401, "Unauthorized: User not found"));
    }

    req.user = user;
    return next();
  } catch (_error) {
    return next(new ApiError(401, "Unauthorized: Invalid or expired token"));
  }
};

const authorize = (...allowedRoles) => (req, _res, next) => {
  if (!req.user || !allowedRoles.includes(req.user.role)) {
    return next(new ApiError(403, "Forbidden: Access denied"));
  }

  return next();
};

module.exports = {
  protect,
  authorize,
  ROLES,
};
