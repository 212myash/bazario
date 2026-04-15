const Wishlist = require("../models/wishlist.model");
const Product = require("../models/product.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");

const getRefId = (value) => (value && value._id ? value._id.toString() : value.toString());

const getOrCreateWishlist = async (userId) => {
  let wishlist = await Wishlist.findOne({ user: userId }).populate(
    "products",
    "title slug price discountedPrice images stock ratingAverage",
  );

  if (!wishlist) {
    wishlist = await Wishlist.create({ user: userId, products: [] });
  }

  return wishlist;
};

const getWishlist = asyncHandler(async (req, res) => {
  const wishlist = await getOrCreateWishlist(req.user._id);
  return res.status(200).json(new ApiResponse(200, "Wishlist fetched", wishlist));
});

const addToWishlist = asyncHandler(async (req, res) => {
  const { productId } = req.body;
  if (!productId) {
    throw new ApiError(400, "productId is required");
  }

  const product = await Product.findById(productId);
  if (!product || !product.isPublished) {
    throw new ApiError(404, "Product not found");
  }

  const wishlist = await getOrCreateWishlist(req.user._id);
  if (!wishlist.products.some((id) => getRefId(id) === productId)) {
    wishlist.products.push(productId);
    await wishlist.save();
  }

  const updated = await Wishlist.findById(wishlist._id).populate(
    "products",
    "title slug price discountedPrice images stock ratingAverage",
  );

  return res.status(200).json(new ApiResponse(200, "Added to wishlist", updated));
});

const removeFromWishlist = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const wishlist = await getOrCreateWishlist(req.user._id);

  wishlist.products = wishlist.products.filter((id) => getRefId(id) !== productId);
  await wishlist.save();

  const updated = await Wishlist.findById(wishlist._id).populate(
    "products",
    "title slug price discountedPrice images stock ratingAverage",
  );

  return res.status(200).json(new ApiResponse(200, "Removed from wishlist", updated));
});

module.exports = {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
};
