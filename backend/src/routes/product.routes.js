const express = require("express");
const {
  createProduct,
  listProducts,
  getProductBySlug,
  updateProduct,
  deleteProduct,
} = require("../controllers/product.controller");
const { protect, authorize, ROLES } = require("../middleware/auth.middleware");

const router = express.Router();

router.get("/", listProducts);
router.get("/:slug", getProductBySlug);
router.post("/", protect, authorize(ROLES.ADMIN), createProduct);
router.patch("/:productId", protect, authorize(ROLES.ADMIN), updateProduct);
router.delete("/:productId", protect, authorize(ROLES.ADMIN), deleteProduct);

module.exports = router;
