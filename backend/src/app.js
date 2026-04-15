const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const mongoSanitize = require("express-mongo-sanitize");
const hpp = require("hpp");
const rateLimit = require("express-rate-limit");
const cookieParser = require("cookie-parser");

const env = require("./config/env");
const routes = require("./routes");
const { notFound, errorHandler } = require("./middleware/error.middleware");

const app = express();

app.use(
  cors({
    origin: env.CLIENT_URL === "*" ? true : env.CLIENT_URL,
    credentials: true,
  }),
);
app.use(helmet());
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 300,
    standardHeaders: "draft-7",
    legacyHeaders: false,
  }),
);
app.use(morgan(env.NODE_ENV === "production" ? "combined" : "dev"));
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(mongoSanitize());
app.use(hpp());

app.get("/api/health", (_req, res) => {
  res.status(200).json({ success: true, message: "Backend is healthy" });
});

app.use("/api", routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
