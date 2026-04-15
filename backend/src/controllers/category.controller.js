const Category = require("../models/category.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");
const toSlug = require("../utils/slugify");

const createCategory = asyncHandler(async (req, res) => {
  const { name, description } = req.body;

  if (!name) {
    throw new ApiError(400, "Category name is required");
  }

  const category = await Category.create({
    name,
    description,
    slug: toSlug(name),
  });

  return res.status(201).json(new ApiResponse(201, "Category created", category));
});

const listCategories = asyncHandler(async (_req, res) => {
  const categories = await Category.find({ isActive: true }).sort({ name: 1 });
  return res.status(200).json(new ApiResponse(200, "Categories fetched", categories));
});

const updateCategory = asyncHandler(async (req, res) => {
  const category = await Category.findById(req.params.categoryId);
  if (!category) {
    throw new ApiError(404, "Category not found");
  }

  if (req.body.name) {
    category.name = req.body.name;
    category.slug = toSlug(req.body.name);
  }
  if (req.body.description !== undefined) {
    category.description = req.body.description;
  }
  if (req.body.isActive !== undefined) {
    category.isActive = Boolean(req.body.isActive);
  }

  await category.save();
  return res.status(200).json(new ApiResponse(200, "Category updated", category));
});

const deleteCategory = asyncHandler(async (req, res) => {
  const category = await Category.findByIdAndDelete(req.params.categoryId);
  if (!category) {
    throw new ApiError(404, "Category not found");
  }

  return res.status(200).json(new ApiResponse(200, "Category deleted"));
});

module.exports = {
  createCategory,
  listCategories,
  updateCategory,
  deleteCategory,
};
