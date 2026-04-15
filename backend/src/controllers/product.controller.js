const Product = require("../models/product.model");
const Category = require("../models/category.model");
const Review = require("../models/review.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");
const { getPagination } = require("../utils/pagination");
const toSlug = require("../utils/slugify");

const createProduct = asyncHandler(async (req, res) => {
  const { title, description, price, stock, category, brand, discountedPrice, tags } = req.body;

  if (!title || !description || !price || stock === undefined || !category) {
    throw new ApiError(400, "title, description, price, stock and category are required");
  }

  const categoryExists = await Category.findById(category);
  if (!categoryExists) {
    throw new ApiError(404, "Category not found");
  }

  const slugBase = toSlug(title);
  const slug = `${slugBase}-${Date.now()}`;

  const product = await Product.create({
    title,
    slug,
    description,
    price,
    discountedPrice,
    stock,
    category,
    brand,
    tags: Array.isArray(tags) ? tags : [],
  });

  return res.status(201).json(new ApiResponse(201, "Product created", product));
});

const listProducts = asyncHandler(async (req, res) => {
  const { page, limit, skip } = getPagination(req.query);
  const { category, minPrice, maxPrice, search, sortBy = "createdAt", sortOrder = "desc" } = req.query;

  const filter = { isPublished: true };
  if (category) filter.category = category;
  if (minPrice || maxPrice) {
    filter.price = {};
    if (minPrice) filter.price.$gte = Number(minPrice);
    if (maxPrice) filter.price.$lte = Number(maxPrice);
  }
  if (search) {
    filter.$text = { $search: search };
  }

  const sort = { [sortBy]: sortOrder === "asc" ? 1 : -1 };

  const [items, total] = await Promise.all([
    Product.find(filter).populate("category", "name slug").sort(sort).skip(skip).limit(limit),
    Product.countDocuments(filter),
  ]);

  const totalPages = Math.ceil(total / limit);

  return res.status(200).json(
    new ApiResponse(200, "Products fetched", items, {
      pagination: { page, limit, total, totalPages },
    }),
  );
});

const getProductBySlug = asyncHandler(async (req, res) => {
  const product = await Product.findOne({ slug: req.params.slug })
    .populate("category", "name slug")
    .lean();

  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  const reviews = await Review.find({ product: product._id })
    .populate("user", "name avatarUrl")
    .sort({ createdAt: -1 })
    .limit(10);

  product.reviews = reviews;

  return res.status(200).json(new ApiResponse(200, "Product details fetched", product));
});

const updateProduct = asyncHandler(async (req, res) => {
  const product = await Product.findById(req.params.productId);
  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  [
    "title",
    "description",
    "price",
    "discountedPrice",
    "stock",
    "category",
    "brand",
    "tags",
    "isPublished",
  ].forEach((field) => {
    if (req.body[field] !== undefined) {
      product[field] = req.body[field];
    }
  });

  if (req.body.title) {
    product.slug = `${toSlug(req.body.title)}-${Date.now()}`;
  }

  await product.save();
  return res.status(200).json(new ApiResponse(200, "Product updated", product));
});

const deleteProduct = asyncHandler(async (req, res) => {
  const product = await Product.findByIdAndDelete(req.params.productId);
  if (!product) {
    throw new ApiError(404, "Product not found");
  }

  return res.status(200).json(new ApiResponse(200, "Product deleted"));
});

module.exports = {
  createProduct,
  listProducts,
  getProductBySlug,
  updateProduct,
  deleteProduct,
};
