const fs = require("fs");
const path = require("path");
const mongoose = require("mongoose");
const dotenv = require("dotenv");

const Category = require("../models/category.model");
const Product = require("../models/product.model");
const toSlug = require("../utils/slugify");

dotenv.config({ path: ".env" });

const parseJsonFile = (filePath) => {
  const raw = fs.readFileSync(filePath, "utf8");
  const parsed = JSON.parse(raw);

  if (!Array.isArray(parsed.categories)) {
    throw new Error("Invalid JSON: 'categories' must be an array");
  }

  if (!Array.isArray(parsed.products)) {
    throw new Error("Invalid JSON: 'products' must be an array");
  }

  return parsed;
};

const getJsonPath = () => {
  const cliPath = process.argv[2] || "data/catalog.json";
  return path.isAbsolute(cliPath)
    ? cliPath
    : path.resolve(process.cwd(), cliPath);
};

const run = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI missing in .env");
    }

    const jsonPath = getJsonPath();

    if (!fs.existsSync(jsonPath)) {
      throw new Error(`JSON file not found: ${jsonPath}`);
    }

    const payload = parseJsonFile(jsonPath);

    await mongoose.connect(process.env.MONGODB_URI);

    const categoryMap = new Map();
    let categoriesCreated = 0;

    for (const categoryInput of payload.categories) {
      const name = (categoryInput.name || "").toString().trim();
      if (!name) {
        continue;
      }

      const slug = toSlug(name);
      let category = await Category.findOne({ slug });

      if (!category) {
        category = await Category.create({
          name,
          slug,
          description: (categoryInput.description || "").toString().trim(),
          isActive:
            categoryInput.isActive === undefined
              ? true
              : Boolean(categoryInput.isActive),
        });
        categoriesCreated += 1;
      }

      categoryMap.set(name.toLowerCase(), category);
    }

    let productsCreated = 0;
    let productsSkipped = 0;

    for (let i = 0; i < payload.products.length; i += 1) {
      const item = payload.products[i];

      const title = (item.title || "").toString().trim();
      const description = (item.description || "").toString().trim();
      const categoryName = (item.category || "").toString().trim().toLowerCase();

      if (!title || !description || !categoryName) {
        productsSkipped += 1;
        continue;
      }

      const category = categoryMap.get(categoryName);
      if (!category) {
        productsSkipped += 1;
        continue;
      }

      const price = Number(item.price);
      const stock = Number(item.stock);
      if (Number.isNaN(price) || Number.isNaN(stock)) {
        productsSkipped += 1;
        continue;
      }

      const duplicate = await Product.findOne({
        title,
        category: category._id,
        brand: (item.brand || "").toString().trim(),
      }).select("_id");

      if (duplicate) {
        productsSkipped += 1;
        continue;
      }

      const now = Date.now();
      const slug = `${toSlug(title)}-${now}-${i + 1}`;
      const discountedPrice =
        item.discountedPrice === undefined || item.discountedPrice === null
          ? undefined
          : Number(item.discountedPrice);

      const images = Array.isArray(item.images)
        ? item.images
            .filter((img) => img && img.url)
            .map((img, idx) => ({
              publicId: (img.publicId || `${toSlug(title)}-${idx + 1}`).toString(),
              url: img.url.toString(),
            }))
        : [];

      await Product.create({
        title,
        slug,
        description,
        price,
        discountedPrice,
        stock,
        category: category._id,
        brand: (item.brand || "").toString().trim(),
        tags: Array.isArray(item.tags)
          ? item.tags.map((tag) => tag.toString().trim()).filter(Boolean)
          : [],
        images,
        isPublished:
          item.isPublished === undefined ? true : Boolean(item.isPublished),
      });

      productsCreated += 1;
    }

    console.log(
      `Import complete. Categories created: ${categoriesCreated}, products created: ${productsCreated}, products skipped: ${productsSkipped}`,
    );
  } catch (error) {
    console.error("JSON catalog import failed", error.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
};

run();
