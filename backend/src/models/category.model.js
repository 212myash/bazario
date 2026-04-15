const mongoose = require("mongoose");

const categorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, trim: true, maxlength: 80 },
    slug: { type: String, required: true, unique: true, trim: true, lowercase: true },
    description: { type: String, trim: true, maxlength: 300 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

categorySchema.index({ name: 1 });
categorySchema.index({ slug: 1 });

module.exports = mongoose.model("Category", categorySchema);
