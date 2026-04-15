const express = require("express");
const { createOrUpdateReview, deleteMyReview } = require("../controllers/review.controller");
const { protect } = require("../middleware/auth.middleware");

const router = express.Router();

router.use(protect);

router.post("/:productId", createOrUpdateReview);
router.delete("/:productId", deleteMyReview);

module.exports = router;
