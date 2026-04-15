const Cart = require("../models/cart.model");
const Product = require("../models/product.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");

const getRefId = (value) => (value && value._id ? value._id.toString() : value.toString());

const getOrCreateCart = async (userId) => {
  let cart = await Cart.findOne({ user: userId }).populate("items.product", "title price images stock slug");
  if (!cart) {
    cart = await Cart.create({ user: userId, items: [] });
  }
  return cart;
};

const getMyCart = asyncHandler(async (req, res) => {
  const cart = await getOrCreateCart(req.user._id);
  return res.status(200).json(new ApiResponse(200, "Cart fetched", cart));
});

const addItemToCart = asyncHandler(async (req, res) => {
  const { productId, quantity = 1 } = req.body;
  if (!productId) {
    throw new ApiError(400, "productId is required");
  }

  const product = await Product.findById(productId);
  if (!product || !product.isPublished) {
    throw new ApiError(404, "Product not found");
  }

  if (product.stock < quantity) {
    throw new ApiError(400, "Insufficient stock");
  }

  const cart = await getOrCreateCart(req.user._id);
  const item = cart.items.find((entry) => getRefId(entry.product) === productId);

  if (item) {
    item.quantity += Number(quantity);
  } else {
    cart.items.push({
      product: product._id,
      quantity: Number(quantity),
      priceSnapshot: product.discountedPrice || product.price,
      titleSnapshot: product.title,
      imageSnapshot: product.images[0]?.url,
    });
  }

  await cart.save();
  const updated = await Cart.findById(cart._id).populate("items.product", "title price images stock slug");

  return res.status(200).json(new ApiResponse(200, "Item added to cart", updated));
});

const updateCartItem = asyncHandler(async (req, res) => {
  const { productId, quantity } = req.body;

  if (!productId || quantity === undefined) {
    throw new ApiError(400, "productId and quantity are required");
  }

  if (quantity < 1) {
    throw new ApiError(400, "Quantity must be at least 1");
  }

  const cart = await getOrCreateCart(req.user._id);
  const item = cart.items.find((entry) => getRefId(entry.product) === productId);

  if (!item) {
    throw new ApiError(404, "Item not found in cart");
  }

  const product = await Product.findById(productId);
  if (!product || product.stock < quantity) {
    throw new ApiError(400, "Insufficient stock");
  }

  item.quantity = Number(quantity);
  item.priceSnapshot = product.discountedPrice || product.price;
  await cart.save();

  const updated = await Cart.findById(cart._id).populate("items.product", "title price images stock slug");
  return res.status(200).json(new ApiResponse(200, "Cart item updated", updated));
});

const removeCartItem = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const cart = await getOrCreateCart(req.user._id);

  cart.items = cart.items.filter((entry) => getRefId(entry.product) !== productId);
  await cart.save();

  const updated = await Cart.findById(cart._id).populate("items.product", "title price images stock slug");
  return res.status(200).json(new ApiResponse(200, "Item removed from cart", updated));
});

const clearCart = asyncHandler(async (req, res) => {
  const cart = await getOrCreateCart(req.user._id);
  cart.items = [];
  await cart.save();

  return res.status(200).json(new ApiResponse(200, "Cart cleared", cart));
});

module.exports = {
  getMyCart,
  addItemToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
};
