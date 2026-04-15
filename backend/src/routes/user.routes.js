const express = require("express");
const {
  getMyProfile,
  updateMyProfile,
  addAddress,
  updateAddress,
  deleteAddress,
} = require("../controllers/user.controller");
const { protect } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.get("/me", getMyProfile);
router.patch("/me", updateMyProfile);

router.post("/me/addresses", addAddress);
router.patch("/me/addresses/:addressId", updateAddress);
router.delete("/me/addresses/:addressId", deleteAddress);

module.exports = router;
