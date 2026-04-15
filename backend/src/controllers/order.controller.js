const Cart = require("../models/cart.model");
const Order = require("../models/order.model");
const Product = require("../models/product.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");
const { getPagination } = require("../utils/pagination");

const calculateTotals = (items, shippingFee = 0, taxFee = 0) => {
  const subtotal = items.reduce((sum, item) => sum + item.lineTotal, 0);
  const totalAmount = subtotal + shippingFee + taxFee;
  return { subtotal, shippingFee, taxFee, totalAmount };
};

const placeOrder = asyncHandler(async (req, res) => {
  const { paymentMethod, shippingAddress, shippingFee = 0, taxFee = 0 } = req.body;

  if (!paymentMethod || !shippingAddress) {
    throw new ApiError(400, "paymentMethod and shippingAddress are required");
  }

  const cart = await Cart.findOne({ user: req.user._id }).populate("items.product", "title price discountedPrice stock images");
  if (!cart || cart.items.length === 0) {
    throw new ApiError(400, "Cart is empty");
  }

  const orderItems = [];

  for (const cartItem of cart.items) {
    const product = await Product.findById(cartItem.product._id);
    if (!product || !product.isPublished) {
      throw new ApiError(400, `Product unavailable: ${cartItem.titleSnapshot}`);
    }

    if (product.stock < cartItem.quantity) {
      throw new ApiError(400, `Insufficient stock for ${product.title}`);
    }

    const unitPrice = product.discountedPrice || product.price;
    const lineTotal = unitPrice * cartItem.quantity;

    orderItems.push({
      product: product._id,
      title: product.title,
      image: product.images[0]?.url,
      quantity: cartItem.quantity,
      unitPrice,
      lineTotal,
    });
  }

  const totals = calculateTotals(orderItems, Number(shippingFee), Number(taxFee));

  const order = await Order.create({
    user: req.user._id,
    items: orderItems,
    shippingAddress,
    paymentMethod,
    ...totals,
    paymentStatus: paymentMethod === "cod" ? "pending" : "pending",
  });

  for (const item of orderItems) {
    await Product.findByIdAndUpdate(item.product, { $inc: { stock: -item.quantity } });
  }

  cart.items = [];
  await cart.save();

  return res.status(201).json(new ApiResponse(201, "Order placed", order));
});

const getMyOrders = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);

  const [orders, total] = await Promise.all([
    Order.find({ user: req.user._id }).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Order.countDocuments({ user: req.user._id }),
  ]);

  return res.status(200).json(
    new ApiResponse(200, "Orders fetched", orders, {
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    }),
  );
});

const getOrderById = asyncHandler(async (req, res) => {
  const order = await Order.findOne({ _id: req.params.orderId, user: req.user._id });
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  return res.status(200).json(new ApiResponse(200, "Order fetched", order));
});

const updateOrderStatus = asyncHandler(async (req, res) => {
  const { orderStatus, paymentStatus } = req.body;

  const order = await Order.findById(req.params.orderId);
  if (!order) {
    throw new ApiError(404, "Order not found");
  }

  if (orderStatus) order.orderStatus = orderStatus;
  if (paymentStatus) order.paymentStatus = paymentStatus;
  if (paymentStatus === "paid") order.paidAt = new Date();

  await order.save();

  return res.status(200).json(new ApiResponse(200, "Order updated", order));
});

module.exports = {
  placeOrder,
  getMyOrders,
  getOrderById,
  updateOrderStatus,
};
