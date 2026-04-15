const express = require("express");
const {
  getMyCart,
  addItemToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
} = require("../controllers/cart.controller");
const { protect } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.get("/", getMyCart);
router.post("/items", addItemToCart);
router.patch("/items", updateCartItem);
router.delete("/items/:productId", removeCartItem);
router.delete("/", clearCart);

module.exports = router;
