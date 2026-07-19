import { getIO } from "../socket.js";

export const sendNotification = (data) => {
  try {
    const io = getIO();

    io.emit("notification", {
      message: data.message,
      type: data.type || "info",
      time: new Date(),
    });
  } catch (error) {
    console.error(
      "Notification emit failed:",
      error.message,
    );
  }
};