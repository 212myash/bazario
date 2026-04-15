const Review = require("../models/review.model");
const Product = require("../models/product.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");

const updateProductRatingStats = async (productId) => {
  const stats = await Review.aggregate([
    { $match: { product: productId } },
    {
      $group: {
        _id: "$product",
        avgRating: { $avg: "$rating" },
        count: { $sum: 1 },
      },
    },
  ]);

  if (stats.length === 0) {
    await Product.findByIdAndUpdate(productId, { ratingAverage: 0, ratingCount: 0 });
    return;
  }

  await Product.findByIdAndUpdate(productId, {
    ratingAverage: Number(stats[0].avgRating.toFixed(1)),
    ratingCount: stats[0].count,
  });
};

const createOrUpdateReview = asyncHandler(async (req, res) => {
  const { productId } = req.params;
  const { rating, comment } = req.body;

  if (!rating || rating < 1 || rating > 5) {
    throw new ApiError(400, "Rating should be between 1 and 5");
  }

  const product = await Product.findById(productId);
  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  const review = await Review.findOneAndUpdate(
    { user: req.user._id, product: productId },
    { rating, comment },
    { new: true, upsert: true, setDefaultsOnInsert: true },
  );

  await updateProductRatingStats(product._id);

  return res.status(200).json(new ApiResponse(200, "Review saved", review));
});

const deleteMyReview = asyncHandler(async (req, res) => {
  const { productId } = req.params;

  const review = await Review.findOneAndDelete({ user: req.user._id, product: productId });
  if (!review) {
    throw new ApiError(404, "Review not found");
  }

  await updateProductRatingStats(review.product);

  return res.status(200).json(new ApiResponse(200, "Review deleted"));
});

module.exports = {
  createOrUpdateReview,
  deleteMyReview,
};
