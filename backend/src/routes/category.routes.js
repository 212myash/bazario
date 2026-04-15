const express = require("express");
const {
  createCategory,
  listCategories,
  updateCategory,
  deleteCategory,
} = require("../controllers/category.controller");
const { protect, authorize, ROLES } = require("../middleware/auth.middleware");

const router = express.Router();

router.get("/", listCategories);
router.post("/", protect, authorize(ROLES.ADMIN), createCategory);
router.patch("/:categoryId", protect, authorize(ROLES.ADMIN), updateCategory);
router.delete("/:categoryId", protect, authorize(ROLES.ADMIN), deleteCategory);

module.exports = router;
