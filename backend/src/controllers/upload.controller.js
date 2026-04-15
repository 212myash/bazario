const cloudinary = require("../config/cloudinary");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const ApiResponse = require("../utils/ApiResponse");

const uploadImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new ApiError(400, "No image file provided");
  }

  if (!cloudinary.config().cloud_name) {
    throw new ApiError(500, "Cloudinary is not configured. Please set environment variables.");
  }

  const uploadResult = await new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: "bazario/products", resource_type: "image" },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      },
    );

    stream.end(req.file.buffer);
  });

  return res.status(201).json(
    new ApiResponse(201, "Image uploaded", {
      publicId: uploadResult.public_id,
      url: uploadResult.secure_url,
    }),
  );
});

module.exports = {
  uploadImage,
};
