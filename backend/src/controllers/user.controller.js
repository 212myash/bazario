const User = require("../models/user.model");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");

const getMyProfile = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select("-password -refreshToken");
  return res.status(200).json(new ApiResponse(200, "Profile fetched", user));
});

const updateMyProfile = asyncHandler(async (req, res) => {
  const { name, phone, avatarUrl } = req.body;

  const user = await User.findById(req.user._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (name) user.name = name;
  if (phone) user.phone = phone;
  if (avatarUrl) user.avatarUrl = avatarUrl;

  await user.save();

  return res.status(200).json(new ApiResponse(200, "Profile updated", user));
});

const addAddress = asyncHandler(async (req, res) => {
  const { fullName, phone, street, city, state, postalCode, country, label, isDefault } = req.body;

  if (!fullName || !phone || !street || !city || !state || !postalCode || !country) {
    throw new ApiError(400, "Please provide complete address fields");
  }

  const user = await User.findById(req.user._id);
  if (!user) {
    throw new ApiError(404, "User not found");
  }

  if (isDefault) {
    user.addresses.forEach((address) => {
      address.isDefault = false;
    });
  }

  user.addresses.push({
    fullName,
    phone,
    street,
    city,
    state,
    postalCode,
    country,
    label,
    isDefault: Boolean(isDefault),
  });

  await user.save();

  return res.status(201).json(new ApiResponse(201, "Address added", user.addresses));
});

const updateAddress = asyncHandler(async (req, res) => {
  const { addressId } = req.params;
  const user = await User.findById(req.user._id);

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const address = user.addresses.id(addressId);
  if (!address) {
    throw new ApiError(404, "Address not found");
  }

  Object.keys(req.body).forEach((key) => {
    if (req.body[key] !== undefined) {
      address[key] = req.body[key];
    }
  });

  if (req.body.isDefault === true) {
    user.addresses.forEach((item) => {
      item.isDefault = item._id.toString() === addressId;
    });
  }

  await user.save();

  return res.status(200).json(new ApiResponse(200, "Address updated", user.addresses));
});

const deleteAddress = asyncHandler(async (req, res) => {
  const { addressId } = req.params;
  const user = await User.findById(req.user._id);

  if (!user) {
    throw new ApiError(404, "User not found");
  }

  const address = user.addresses.id(addressId);
  if (!address) {
    throw new ApiError(404, "Address not found");
  }

  address.deleteOne();
  await user.save();

  return res.status(200).json(new ApiResponse(200, "Address deleted", user.addresses));
});

module.exports = {
  getMyProfile,
  updateMyProfile,
  addAddress,
  updateAddress,
  deleteAddress,
};
