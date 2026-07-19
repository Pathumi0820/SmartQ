import { useEffect, useState } from "react";
import api from "../services/api";
import socket from "../services/socket";

function DisplayBoard() {
  const [tokens, setTokens] = useState([]);
  const [time, setTime] = useState(new Date());
  const [isFullScreen, setIsFullScreen] = useState(false);

  useEffect(() => {
    loadTokens();

    socket.on("tokensUpdated", loadTokens);
    socket.on("dashboardUpdated", loadTokens);

    const timer = setInterval(() => setTime(new Date()), 1000);

    const handleFullScreenChange = () => {
      setIsFullScreen(!!document.fullscreenElement);
    };

    document.addEventListener("fullscreenchange", handleFullScreenChange);

    return () => {
      socket.off("tokensUpdated", loadTokens);
      socket.off("dashboardUpdated", loadTokens);
      clearInterval(timer);
      document.removeEventListener("fullscreenchange", handleFullScreenChange);
    };
  }, []);

  const loadTokens = async () => {
    const res = await api.get("/tokens");
    setTokens(res.data);
  };

  const goFullScreen = () => {
    document.documentElement.requestFullscreen();
  };

  const currentToken = tokens.find(
    (t) => t.status === "Serving" || t.status === "Called"
  );

  const waitingTokens = tokens
    .filter((t) => t.status === "Waiting")
    .slice(0, 5);

  const formatToken = (token) =>
    `${token.prefix}${String(token.tokenNumber).padStart(3, "0")}`;

  return (
    <div style={page}>
      <header style={header}>
        <div>
          <h1 style={title}>SmartQ Display Board</h1>
          <p style={subtitle}>Live Hospital Queue Status</p>
        </div>

        <div style={headerRight}>
          <div style={clock}>{time.toLocaleTimeString()}</div>

          {!isFullScreen && (
            <button style={fullScreenBtn} onClick={goFullScreen}>
              Full Screen
            </button>
          )}
        </div>
      </header>

      <section style={hero}>
        <p style={label}>NOW SERVING</p>

        <h2 style={tokenNumber}>
          {currentToken ? formatToken(currentToken) : "---"}
        </h2>

        <p style={patient}>
          {currentToken ? currentToken.patientName : "No patient currently called"}
        </p>

        <p style={dept}>
          {currentToken?.department?.name || "Waiting for next token"}
        </p>
      </section>

      <section style={waitingBox}>
        <h2 style={waitingTitle}>Next Tokens</h2>

        {waitingTokens.length === 0 ? (
          <p style={empty}>No waiting tokens</p>
        ) : (
          waitingTokens.map((token) => (
            <div key={token._id} style={waitingItem}>
              <strong>{formatToken(token)}</strong>
              <span>{token.patientName}</span>
              <span>{token.department?.name}</span>
            </div>
          ))
        )}
      </section>
    </div>
  );
}

const page = {
  height: "100vh",
  background: "linear-gradient(135deg, #020617, #0f172a)",
  color: "#fff",
  padding: "40px",
  boxSizing: "border-box",
  overflow: "hidden",
};

const header = {
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  marginBottom: "36px",
};

const headerRight = {
  display: "flex",
  alignItems: "center",
  gap: "16px",
};

const title = {
  fontSize: "44px",
  margin: 0,
  fontWeight: "900",
};

const subtitle = {
  color: "#cbd5e1",
  margin: "8px 0 0",
  fontSize: "18px",
};

const clock = {
  background: "#ffffff",
  color: "#0f172a",
  padding: "14px 24px",
  borderRadius: "18px",
  fontSize: "28px",
  fontWeight: "800",
};

const fullScreenBtn = {
  background: "#2563eb",
  color: "#ffffff",
  border: "none",
  padding: "16px 24px",
  borderRadius: "18px",
  fontSize: "16px",
  fontWeight: "800",
  cursor: "pointer",
};

const hero = {
  background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
  borderRadius: "34px",
  padding: "50px",
  textAlign: "center",
  boxShadow: "0 20px 50px rgba(37, 99, 235, 0.35)",
  marginBottom: "30px",
};

const label = {
  fontSize: "24px",
  letterSpacing: "4px",
  margin: 0,
  color: "#dbeafe",
  fontWeight: "800",
};

const tokenNumber = {
  fontSize: "120px",
  margin: "16px 0",
  fontWeight: "900",
};

const patient = {
  fontSize: "32px",
  margin: "8px 0",
  fontWeight: "700",
};

const dept = {
  fontSize: "24px",
  color: "#dbeafe",
};

const waitingBox = {
  background: "#ffffff",
  color: "#0f172a",
  borderRadius: "28px",
  padding: "28px",
};

const waitingTitle = {
  marginTop: 0,
  fontSize: "30px",
};

const waitingItem = {
  display: "grid",
  gridTemplateColumns: "1fr 2fr 2fr",
  gap: "20px",
  padding: "18px",
  borderBottom: "1px solid #e5e7eb",
  fontSize: "24px",
  alignItems: "center",
};

const empty = {
  color: "#64748b",
  fontSize: "22px",
  textAlign: "center",
};

export default DisplayBoard;