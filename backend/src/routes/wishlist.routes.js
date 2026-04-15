const express = require("express");
const { getWishlist, addToWishlist, removeFromWishlist } = require("../controllers/wishlist.controller");
const { protect } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.get("/", getWishlist);
router.post("/", addToWishlist);
router.delete("/:productId", removeFromWishlist);

module.exports = router;
