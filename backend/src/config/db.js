const mongoose = require("mongoose");
const env = require("./env");

const connectDB = async () => {
  mongoose.set("strictQuery", true);

  await mongoose.connect(env.MONGODB_URI, {
    maxPoolSize: 20,
    minPoolSize: 5,
    serverSelectionTimeoutMS: 10000,
  });

  console.log("MongoDB connected successfully");
};

module.exports = connectDB;
