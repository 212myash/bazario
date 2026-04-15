const express = require("express");
const {
  createStripeIntent,
  createRazorpayPaymentOrder,
  verifyRazorpayPayment,
} = require("../controllers/payment.controller");
const { protect } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.post("/stripe/intent", createStripeIntent);
router.post("/razorpay/order", createRazorpayPaymentOrder);
router.post("/razorpay/verify", verifyRazorpayPayment);

module.exports = router;
