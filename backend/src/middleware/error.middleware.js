const env = require("../config/env");

const notFound = (req, _res, next) => {
  const error = new Error(`Route not found: ${req.originalUrl}`);
  error.statusCode = 404;
  next(error);
};

const errorHandler = (error, _req, res, _next) => {
  const statusCode = error.statusCode || 500;

  if (env.NODE_ENV !== "production") {
    console.error(error);
  }

  res.status(statusCode).json({
    success: false,
    statusCode,
    message: error.message || "Internal server error",
    details: error.details || null,
    stack: env.NODE_ENV === "production" ? undefined : error.stack,
  });
};

module.exports = {
  notFound,
  errorHandler,
};
