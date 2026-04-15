const Order = require("../models/order.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");
const {
  createStripePaymentIntent,
  createRazorpayOrder,
  verifyRazorpaySignature,
} = require("../services/payment.service");

const createStripeIntent = asyncHandler(async (req, res) => {
  const { orderId, currency = "usd" } = req.body;

  const order = await Order.findOne({ _id: orderId, user: req.user._id });
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  const paymentIntent = await createStripePaymentIntent({
    amount: order.totalAmount,
    currency,
    metadata: { orderId: order._id.toString(), userId: req.user._id.toString() },
  });

  return res.status(200).json(
    new ApiResponse(200, "Stripe payment intent created", {
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    }),
  );
});

const createRazorpayPaymentOrder = asyncHandler(async (req, res) => {
  const { orderId, currency = "INR" } = req.body;

  const order = await Order.findOne({ _id: orderId, user: req.user._id });
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  const razorpayOrder = await createRazorpayOrder({
    amount: order.totalAmount,
    currency,
    receipt: `receipt_${order._id}`,
  });

  return res
    .status(200)
    .json(new ApiResponse(200, "Razorpay order created", { razorpayOrder, keyId: process.env.RAZORPAY_KEY_ID }));
});

const verifyRazorpayPayment = asyncHandler(async (req, res) => {
  const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

  const isValid = verifyRazorpaySignature({
    orderId: razorpayOrderId,
    paymentId: razorpayPaymentId,
    signature: razorpaySignature,
  });

  if (!isValid) {
    throw new ApiError(400, "Invalid payment signature");
  }

  const order = await Order.findOne({ _id: orderId, user: req.user._id });
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  order.paymentStatus = "paid";
  order.transactionId = razorpayPaymentId;
  order.paidAt = new Date();
  await order.save();

  return res.status(200).json(new ApiResponse(200, "Payment verified", order));
});

module.exports = {
  createStripeIntent,
  createRazorpayPaymentOrder,
  verifyRazorpayPayment,
};
