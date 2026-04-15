const mongoose = require("mongoose");
const dotenv = require("dotenv");
const User = require("../models/user.model");
const { ROLES } = require("../constants/roles");

dotenv.config({ path: ".env" });

const run = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI missing in .env");
    }

    const email = process.argv[2] || "admin@bazario.com";
    const password = process.argv[3] || "Admin@12345";

    await mongoose.connect(process.env.MONGODB_URI);

    const existing = await User.findOne({ email });
    if (existing) {
      existing.role = ROLES.ADMIN;
      await existing.save();
      console.log(`Existing user promoted to admin: ${email}`);
    } else {
      await User.create({
        name: "Bazario Admin",
        email,
        password,
        role: ROLES.ADMIN,
      });
      console.log(`Admin user created: ${email}`);
    }
  } catch (error) {
    console.error("Admin seed failed", error.message);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
};

run();
