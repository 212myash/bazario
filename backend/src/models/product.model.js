const mongoose = require("mongoose");

const productImageSchema = new mongoose.Schema(
  {
    publicId: { type: String, required: true },
    url: { type: String, required: true },
  },
  { _id: false },
);

const productSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 160 },
    slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
    description: { type: String, required: true, trim: true, maxlength: 3000 },
    price: { type: Number, required: true, min: 0 },
    discountedPrice: { type: Number, min: 0 },
    stock: { type: Number, required: true, min: 0, default: 0 },
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
      required: true,
      index: true,
    },
    brand: { type: String, trim: true, maxlength: 80, index: true },
    images: { type: [productImageSchema], default: [] },
    tags: { type: [String], default: [] },
    ratingAverage: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0, min: 0 },
    isPublished: { type: Boolean, default: true },
  },
  { timestamps: true },
);

productSchema.index({ title: "text", description: "text", brand: "text" });
productSchema.index({ price: 1 });
productSchema.index({ createdAt: -1 });

module.exports = mongoose.model("Product", productSchema);
