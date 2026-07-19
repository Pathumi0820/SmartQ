import { getAuth } from "firebase-admin/auth";
import firebaseAdminApp from "../config/firebaseAdmin.js";

export const verifyFirebaseToken = async (req, res, next) => {
  try {
    const authorization = req.headers.authorization;

    if (!authorization?.startsWith("Bearer ")) {
      return res.status(401).json({
        message: "Firebase authentication token is required",
      });
    }

    const idToken = authorization.substring(7).trim();

    if (!idToken) {
      return res.status(401).json({
        message: "Authentication token is missing",
      });
    }

    const decodedToken = await getAuth(
      firebaseAdminApp,
    ).verifyIdToken(idToken);

    req.firebaseUser = decodedToken;
    next();
  } catch (error) {
    console.error("Firebase authentication error:", error.message);

    return res.status(401).json({
      message: "Invalid or expired authentication token",
    });
  }
};