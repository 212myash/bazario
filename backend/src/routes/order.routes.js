const express = require("express");
const { placeOrder, getMyOrders, getOrderById, updateOrderStatus } = require("../controllers/order.controller");
const { protect, authorize, ROLES } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.post("/", placeOrder);
router.get("/my", getMyOrders);
router.get("/my/:orderId", getOrderById);
router.patch("/:orderId/status", authorize(ROLES.ADMIN), updateOrderStatus);

module.exports = router;
