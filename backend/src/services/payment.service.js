const Stripe = require("stripe");
const Razorpay = require("razorpay");
const crypto = require("crypto");
const env = require("../config/env");

const stripe = env.STRIPE_SECRET_KEY ? new Stripe(env.STRIPE_SECRET_KEY) : null;

const razorpay =
  env.RAZORPAY_KEY_ID && env.RAZORPAY_KEY_SECRET
    ? new Razorpay({ key_id: env.RAZORPAY_KEY_ID, key_secret: env.RAZORPAY_KEY_SECRET })
    : null;

const createStripePaymentIntent = async ({ amount, currency = "usd", metadata = {} }) => {
  if (!stripe) {
    throw new Error("Stripe is not configured");
  }

  return stripe.paymentIntents.create({
    amount: Math.round(amount * 100),
    currency,
    metadata,
    automatic_payment_methods: { enabled: true },
  });
};

const createRazorpayOrder = async ({ amount, currency = "INR", receipt }) => {
  if (!razorpay) {
    throw new Error("Razorpay is not configured");
  }

  return razorpay.orders.create({
    amount: Math.round(amount * 100),
    currency,
    receipt,
  });
};

const verifyRazorpaySignature = ({ orderId, paymentId, signature }) => {
  const sign = crypto
    .createHmac("sha256", env.RAZORPAY_KEY_SECRET)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  return sign === signature;
};

module.exports = {
  createStripePaymentIntent,
  createRazorpayOrder,
  verifyRazorpaySignature,
};
