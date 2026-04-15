const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const { ROLES } = require("../constants/roles");

const addressSchema = new mongoose.Schema(
  {
    label: { type: String, trim: true, maxlength: 50 },
    fullName: { type: String, trim: true, maxlength: 80 },
    phone: { type: String, trim: true, maxlength: 20 },
    street: { type: String, trim: true, required: true },
    city: { type: String, trim: true, required: true },
    state: { type: String, trim: true, required: true },
    postalCode: { type: String, trim: true, required: true },
    country: { type: String, trim: true, required: true, default: "India" },
    isDefault: { type: Boolean, default: false },
  },
  { _id: true },
);

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, minlength: 2, maxlength: 80 },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    password: { type: String, required: true, minlength: 6, select: false },
    phone: { type: String, trim: true, maxlength: 20 },
    avatarUrl: { type: String, trim: true },
    role: { type: String, enum: Object.values(ROLES), default: ROLES.USER },
    addresses: { type: [addressSchema], default: [] },
    refreshToken: { type: String, select: false },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

userSchema.index({ email: 1 });

userSchema.pre("save", async function hashPassword(next) {
  if (!this.isModified("password")) {
    return next();
  }

  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  return next();
});

userSchema.methods.comparePassword = async function comparePassword(plainPassword) {
  return bcrypt.compare(plainPassword, this.password);
};

module.exports = mongoose.model("User", userSchema);
