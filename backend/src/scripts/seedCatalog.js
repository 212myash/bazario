const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Category = require("../models/category.model");
const Product = require("../models/product.model");
const toSlug = require("../utils/slugify");

dotenv.config({ path: ".env" });

const CATEGORY_SEED = [
  {
    name: "Men Fashion",
    description: "Shirts, jeans, jackets, footwear, and accessories for men.",
    brands: ["UrbanEdge", "NorthTrail", "DenimLab", "IconFit"],
    keywords: ["men", "casual", "formal", "street"],
  },
  {
    name: "Women Fashion",
    description: "Dresses, tops, ethnic wear, and women lifestyle essentials.",
    brands: ["LunaWear", "VelvetBloom", "AstraStyle", "ChicNest"],
    keywords: ["women", "style", "party", "daily"],
  },
  {
    name: "Kids",
    description: "Comfortable and playful fashion for babies, boys, and girls.",
    brands: ["TinyTrend", "PlayNest", "HappyCub", "KiddoSpark"],
    keywords: ["kids", "school", "play", "comfort"],
  },
  {
    name: "Shoes",
    description: "Sneakers, formal shoes, sandals, and sports footwear.",
    brands: ["StrideX", "WalkPro", "PulseRun", "ComfortStep"],
    keywords: ["shoes", "sneakers", "running", "comfort"],
  },
  {
    name: "Bags",
    description: "Backpacks, handbags, office bags, and travel luggage.",
    brands: ["CarryOn", "BagCraft", "NomadPack", "PrimeTote"],
    keywords: ["bags", "travel", "office", "daily"],
  },
  {
    name: "Watches",
    description: "Analog, digital, smart, and premium watches for all.",
    brands: ["Chronix", "TimeNest", "PulseTick", "AxisHour"],
    keywords: ["watches", "premium", "classic", "smart"],
  },
  {
    name: "Beauty",
    description: "Skincare, makeup, grooming, and personal care products.",
    brands: ["GlowLab", "SkinVerse", "PureAura", "DailyBlush"],
    keywords: ["beauty", "care", "skin", "makeup"],
  },
  {
    name: "Electronics",
    description: "Headphones, accessories, gadgets, and daily electronics.",
    brands: ["Voltix", "NeoTech", "ByteCore", "SparkWave"],
    keywords: ["electronics", "gadgets", "audio", "smart"],
  },
  {
    name: "Home Decor",
    description: "Modern decor, storage, lighting, and comfort essentials.",
    brands: ["NestAura", "HomeBloom", "Decora", "CozyRoot"],
    keywords: ["home", "decor", "living", "design"],
  },
  {
    name: "Sports",
    description: "Fitness wear, training accessories, and sports essentials.",
    brands: ["FitBolt", "PowerPlay", "ActiveCore", "MoveMax"],
    keywords: ["sports", "fitness", "training", "active"],
  },
  {
    name: "Accessories",
    description: "Belts, wallets, sunglasses, caps, and style accessories.",
    brands: ["AccentLine", "PrimeWear", "StyleGrid", "UrbanAccent"],
    keywords: ["accessories", "style", "daily", "premium"],
  },
  {
    name: "Winter Wear",
    description: "Hoodies, sweatshirts, jackets, and seasonal essentials.",
    brands: ["FrostLine", "WarmNest", "PolarFit", "SnowThread"],
    keywords: ["winter", "warm", "hoodie", "jacket"],
  },
];

const PRODUCT_ADJECTIVES = [
  "Classic",
  "Modern",
  "Premium",
  "Essential",
  "Comfort",
  "Signature",
  "Everyday",
  "Limited",
  "Elegant",
  "Smart",
  "Sport",
  "Casual",
  "Urban",
  "Lightweight",
  "Pro",
];

const PRODUCT_ITEMS = [
  "Edition",
  "Series",
  "Collection",
  "Pack",
  "Style",
  "Fit",
  "Select",
  "Line",
  "Choice",
  "Range",
  "Model",
  "Wear",
  "Bundle",
  "Set",
  "Drop",
];

const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
const randomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

const categoryPriceRange = (categoryName) => {
  const lower = categoryName.toLowerCase();
  if (lower.includes("electronics") || lower.includes("watches")) {
    return { min: 1499, max: 12999 };
  }
  if (lower.includes("bags") || lower.includes("winter")) {
    return { min: 799, max: 5999 };
  }
  if (lower.includes("beauty") || lower.includes("accessories")) {
    return { min: 299, max: 3499 };
  }
  return { min: 499, max: 4999 };
};

const createDescription = (categoryName, keyword) => {
  return `${categoryName} product crafted for ${keyword} use with premium quality, durable finish, and all-day comfort. Designed for style, performance, and value.`;
};

const run = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI missing in .env");
    }

    const rawCount = Number(process.argv[2] || 60);
    const targetCount = Math.max(50, Math.min(100, Number.isNaN(rawCount) ? 60 : rawCount));

    await mongoose.connect(process.env.MONGODB_URI);

    const categories = [];

    for (const seed of CATEGORY_SEED) {
      const slug = toSlug(seed.name);
      let category = await Category.findOne({ slug });

      if (!category) {
        category = await Category.create({
          name: seed.name,
          slug,
          description: seed.description,
          isActive: true,
        });
      }

      categories.push({
        ...seed,
        _id: category._id,
      });
    }

    const now = Date.now();
    const productDocs = [];

    for (let i = 0; i < targetCount; i += 1) {
      const category = categories[i % categories.length];
      const { min, max } = categoryPriceRange(category.name);
      const basePrice = randomInt(min, max);
      const discountPercent = randomInt(0, 35);
      const discountedPrice = discountPercent > 0
        ? Math.max(1, Math.round(basePrice * (1 - discountPercent / 100)))
        : undefined;

      const adjective = pick(PRODUCT_ADJECTIVES);
      const item = pick(PRODUCT_ITEMS);
      const keyword = pick(category.keywords);
      const title = `${adjective} ${category.name} ${item} ${i + 1}`;

      productDocs.push({
        title,
        slug: `${toSlug(title)}-${now}-${i + 1}`,
        description: createDescription(category.name, keyword),
        price: basePrice,
        discountedPrice,
        stock: randomInt(8, 140),
        category: category._id,
        brand: pick(category.brands),
        tags: [category.name.toLowerCase(), keyword, adjective.toLowerCase()],
        images: [],
        isPublished: true,
      });
    }

    const created = await Product.insertMany(productDocs, { ordered: false });

    console.log(`Catalog seed complete. Categories ensured: ${categories.length}. Products added: ${created.length}.`);
  } catch (error) {
    console.error("Catalog seed failed", error.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
};

run();
