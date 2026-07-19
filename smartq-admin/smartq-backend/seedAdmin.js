import dotenv from "dotenv";
import bcrypt from "bcryptjs";
import connectDB from "./config/db.js";
import User from "./models/User.js";

dotenv.config();
connectDB();

const seedAdmin = async () => {
  const exists = await User.findOne({ email: "admin@smartq.com" });

  if (exists) {
    console.log("Super admin already exists");
    process.exit();
  }

  const hashedPassword = await bcrypt.hash("Admin123456", 10);

  await User.create({
    fullName: "Super Admin",
    email: "admin@smartq.com",
    password: hashedPassword,
    role: "super_admin",
    status: "Active",
    isFirstLogin: true,
  });

  console.log("Super admin created");
  process.exit();
};

seedAdmin();