import dotenv from "dotenv";

dotenv.config();

import express from "express";
import cors from "cors";
import http from "http";
import { Server } from "socket.io";

import connectDB from "./config/db.js";
import "./config/firebaseAdmin.js";

import authRoutes from "./routes/authRoutes.js";
import hospitalRoutes from "./routes/hospitalRoutes.js";
import departmentRoutes from "./routes/departmentRoutes.js";
import userRoutes from "./routes/userRoutes.js";
import tokenRoutes from "./routes/tokenRoutes.js";
import appointmentRoutes from "./routes/appointmentRoutes.js";
import dashboardRoutes from "./routes/dashboardRoutes.js";
import reportRoutes from "./routes/reportRoutes.js";
import mobileRoutes from "./routes/mobileRoutes.js";
import { setIO } from "./socket.js";
import queueSessionRoutes from "./routes/queueSessionRoutes.js";

const app = express();
const server = http.createServer(app);

const allowedOrigins = [
  "http://localhost:5173",
  "http://localhost:5174",
];

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
    ],
    credentials: true,
  },
  transports: ["websocket", "polling"],
});

// Makes Socket.IO available inside routes using:
// const io = req.app.get("io");
setIO(io);
app.set("io", io);

app.use(
  cors({
    origin: allowedOrigins,
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
    ],
    credentials: true,
  }),
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.get("/", (req, res) => {
  return res.json({
    message: "SmartQ API running",
    socket: "Socket.IO enabled",
  });
});
app.use("/api/auth", authRoutes);
app.use("/api/hospitals", hospitalRoutes);
app.use("/api/departments", departmentRoutes);
app.use("/api/users", userRoutes);
app.use("/api/tokens", tokenRoutes);
app.use("/api/appointments", appointmentRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/mobile", mobileRoutes);
app.use("/api/queue-sessions", queueSessionRoutes);


io.on("connection", (socket) => {
  console.log("Socket connected:", socket.id);

  socket.on("joinTokenRoom", (tokenId) => {
  const room = `token:${tokenId}`;

  socket.join(room);

  console.log(`Socket ${socket.id} joined ${room}`);
  console.log("Room members:", io.sockets.adapter.rooms.get(room)?.size ?? 0);

  socket.emit("tokenRoomJoined", {
    tokenId,
    room,
  });
});

  socket.on("leaveTokenRoom", (tokenId) => {
    const normalizedTokenId =
      tokenId?.toString().trim();

    if (!normalizedTokenId) return;

    const roomName = `token:${normalizedTokenId}`;

    socket.leave(roomName);

    console.log(
      `Socket ${socket.id} left ${roomName}`,
    );
  });

  socket.on("joinDepartmentRoom", (departmentId) => {
    const normalizedDepartmentId =
      departmentId?.toString().trim();

    if (!normalizedDepartmentId) {
      socket.emit("socketError", {
        message: "Department ID is required",
      });
      return;
    }

    const roomName =
      `department:${normalizedDepartmentId}`;

    socket.join(roomName);

    console.log(
      `Socket ${socket.id} joined ${roomName}`,
    );

    socket.emit("departmentRoomJoined", {
      departmentId: normalizedDepartmentId,
      room: roomName,
    });
  });

  socket.on("leaveDepartmentRoom", (departmentId) => {
    const normalizedDepartmentId =
      departmentId?.toString().trim();

    if (!normalizedDepartmentId) return;

    const roomName =
      `department:${normalizedDepartmentId}`;

    socket.leave(roomName);

    console.log(
      `Socket ${socket.id} left ${roomName}`,
    );
  });

  socket.on("disconnect", (reason) => {
    console.log(
      `Socket disconnected: ${socket.id}. Reason: ${reason}`,
    );
  });

  socket.on("error", (error) => {
    console.error(
      `Socket error for ${socket.id}:`,
      error,
    );
  });
});

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await connectDB();

    server.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on port ${PORT}`);
      console.log("Socket.IO server enabled");
    });
  } catch (error) {
    console.error(
      "Failed to start server:",
      error.message,
    );

    process.exit(1);
  }
};

startServer();