const express = require("express");

const authRoutes = require("./auth.routes");
const userRoutes = require("./user.routes");
const categoryRoutes = require("./category.routes");
const productRoutes = require("./product.routes");
const cartRoutes = require("./cart.routes");
const orderRoutes = require("./order.routes");
const paymentRoutes = require("./payment.routes");
const reviewRoutes = require("./review.routes");
const wishlistRoutes = require("./wishlist.routes");
const uploadRoutes = require("./upload.routes");
const adminRoutes = require("./admin.routes");

const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/categories", categoryRoutes);
router.use("/products", productRoutes);
router.use("/cart", cartRoutes);
router.use("/orders", orderRoutes);
router.use("/payments", paymentRoutes);
router.use("/reviews", reviewRoutes);
router.use("/wishlist", wishlistRoutes);
router.use("/upload", uploadRoutes);
router.use("/admin", adminRoutes);

module.exports = router;
