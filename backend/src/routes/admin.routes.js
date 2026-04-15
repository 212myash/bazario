const express = require("express");
const { getDashboardStats, listAllOrders } = require("../controllers/admin.controller");
const { protect, authorize, ROLES } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect, authorize(ROLES.ADMIN));

router.get("/dashboard", getDashboardStats);
router.get("/orders", listAllOrders);

module.exports = router;
