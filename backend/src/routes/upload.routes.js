const express = require("express");
const { uploadImage } = require("../controllers/upload.controller");
const { protect, authorize, ROLES } = require("../middleware/auth.middleware");
const upload = require("../middleware/upload.middleware");

const router = express.Router();

router.post("/image", protect, authorize(ROLES.ADMIN), upload.single("image"), uploadImage);

module.exports = router;
