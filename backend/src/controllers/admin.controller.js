const User = require("../models/user.model");
const Product = require("../models/product.model");
const Order = require("../models/order.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiResponse = require("../utils/ApiResponse");
const { getPagination } = require("../utils/pagination");

const getDashboardStats = asyncHandler(async (_req, res) => {
  const [usersCount, productsCount, ordersCount, revenueAgg] = await Promise.all([
    User.countDocuments({}),
    Product.countDocuments({}),
    Order.countDocuments({}),
    Order.aggregate([
      { $match: { paymentStatus: "paid" } },
      { $group: { _id: null, totalRevenue: { $sum: "$totalAmount" } } },
    ]),
  ]);

  const revenue = revenueAgg[0]?.totalRevenue || 0;

  return res.status(200).json(
    new ApiResponse(200, "Admin dashboard stats", {
      usersCount,
      productsCount,
      ordersCount,
      totalRevenue: revenue,
    }),
  );
});

const listAllOrders = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const filter = {};

  if (req.query.orderStatus) {
    filter.orderStatus = req.query.orderStatus;
  }

  const [orders, total] = await Promise.all([
    Order.find(filter).populate("user", "name email").sort({ createdAt: -1 }).skip(skip).limit(limit),
    Order.countDocuments(filter),
  ]);

  return res.status(200).json(
    new ApiResponse(200, "All orders fetched", orders, {
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    }),
  );
});

module.exports = {
  getDashboardStats,
  listAllOrders,
};
