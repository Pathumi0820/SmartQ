import {
  useCallback,
  useEffect,
  useRef,
  useState,
} from "react";

import {
  Html5QrcodeScanner,
} from "html5-qrcode";

import api from "../services/api";

function VerifyPatient() {
  const [tokenNumber, setTokenNumber] =
    useState("");

  const [result, setResult] =
    useState(null);

  const [loading, setLoading] =
    useState(false);

  const [scannerOpen, setScannerOpen] =
    useState(false);

  const [errorMessage, setErrorMessage] =
    useState("");

  const scannerRef = useRef(null);

  /*
  |--------------------------------------------------------------------------
  | Normalize Token Code
  |--------------------------------------------------------------------------
  |
  | Supports:
  | OPD001
  | https://example.com/verify/OPD001
  | {"tokenCode":"OPD001"}
  | token=OPD001|hospital=...
  |
  */

  const normalizeTokenCode = useCallback(
    (value) => {
      const rawValue = String(
        value ?? "",
      ).trim();

      if (!rawValue) {
        return "";
      }

      try {
        const parsedValue =
          JSON.parse(rawValue);

        if (
          parsedValue &&
          typeof parsedValue ===
            "object"
        ) {
          const jsonToken =
            parsedValue.tokenCode ??
            parsedValue.tokenNumber ??
            parsedValue.token ??
            "";

          if (jsonToken) {
            return String(jsonToken)
              .trim()
              .toUpperCase();
          }
        }
      } catch {
        // The QR content is not JSON.
      }

      const oldQrMatch =
        rawValue.match(
          /(?:^|\|)token=([^|]+)/i,
        );

      if (oldQrMatch?.[1]) {
        return decodeURIComponent(
          oldQrMatch[1],
        )
          .trim()
          .toUpperCase();
      }

      try {
        const parsedUrl =
          new URL(rawValue);

        const queryToken =
          parsedUrl.searchParams.get(
            "token",
          ) ??
          parsedUrl.searchParams.get(
            "tokenCode",
          );

        if (queryToken) {
          return queryToken
            .trim()
            .toUpperCase();
        }

        const pathParts =
          parsedUrl.pathname
            .split("/")
            .filter(Boolean);

        if (pathParts.length > 0) {
          return decodeURIComponent(
            pathParts[
              pathParts.length - 1
            ],
          )
            .trim()
            .toUpperCase();
        }
      } catch {
        // The QR content is not a URL.
      }

      if (rawValue.includes("/")) {
        const pathParts =
          rawValue
            .split("/")
            .filter(Boolean);

        if (pathParts.length > 0) {
          return decodeURIComponent(
            pathParts[
              pathParts.length - 1
            ],
          )
            .trim()
            .toUpperCase();
        }
      }

      return rawValue
        .trim()
        .toUpperCase();
    },
    [],
  );

  const verifyToken = useCallback(
    async (value) => {
      const normalizedCode =
        normalizeTokenCode(value);

      if (!normalizedCode) {
        setResult(null);
        setErrorMessage(
          "Please enter or scan a valid token number.",
        );
        return;
      }

      try {
        setLoading(true);
        setResult(null);
        setErrorMessage("");
        setTokenNumber(normalizedCode);

        const response = await api.get(
          `/tokens/verify/${encodeURIComponent(
            normalizedCode,
          )}`,
        );

        const responseData =
          response.data;

        if (
          !responseData ||
          responseData.verified !== true
        ) {
          setErrorMessage(
            responseData?.message ??
              "Invalid token. Patient not found.",
          );

          return;
        }

        setResult(responseData);
      } catch (error) {
        console.error(
          "Token verification error:",
          error,
        );

        const message =
          error?.response?.data?.message ??
          "Invalid token. Patient not found.";

        setErrorMessage(message);
      } finally {
        setLoading(false);
      }
    },
    [normalizeTokenCode],
  );

  const closeScanner =
    useCallback(async () => {
      const scanner =
        scannerRef.current;

      scannerRef.current = null;

      if (scanner) {
        try {
          await scanner.clear();
        } catch (error) {
          console.debug(
            "Scanner cleanup skipped:",
            error,
          );
        }
      }

      setScannerOpen(false);
    }, []);

  useEffect(() => {
    if (!scannerOpen) {
      return undefined;
    }

    let scannerDisposed = false;

    const scanner =
      new Html5QrcodeScanner(
        "qr-reader",
        {
          fps: 10,
          qrbox: {
            width: 250,
            height: 250,
          },
          aspectRatio: 1,
          rememberLastUsedCamera:
            true,
          showTorchButtonIfSupported:
            true,
        },
        false,
      );

    scannerRef.current = scanner;

    scanner.render(
      async (decodedText) => {
        if (scannerDisposed) {
          return;
        }

        scannerDisposed = true;

        const normalizedCode =
          normalizeTokenCode(
            decodedText,
          );

        await closeScanner();

        if (!normalizedCode) {
          setErrorMessage(
            "The scanned QR code does not contain a valid token number.",
          );
          return;
        }

        await verifyToken(
          normalizedCode,
        );
      },
      () => {
        // Scan failures happen continuously while
        // the camera is searching, so no UI error is needed.
      },
    );

    return () => {
      scannerDisposed = true;

      if (
        scannerRef.current ===
        scanner
      ) {
        scannerRef.current = null;
      }

      scanner
        .clear()
        .catch(() => {});
    };
  }, [
    closeScanner,
    normalizeTokenCode,
    scannerOpen,
    verifyToken,
  ]);

  const handleSubmit = (
    event,
  ) => {
    event.preventDefault();

    verifyToken(tokenNumber);
  };

  const toggleScanner = async () => {
    setResult(null);
    setErrorMessage("");

    if (scannerOpen) {
      await closeScanner();
      return;
    }

    setScannerOpen(true);
  };

  return (
    <div style={page}>
      <div style={headingSection}>
        <h1 style={heading}>
          Verify Patient
        </h1>

        <p style={subtitle}>
          Verify a patient using a token
          number or QR code.
        </p>
      </div>

      <form
        style={card}
        onSubmit={handleSubmit}
      >
        <input
          style={input}
          type="text"
          placeholder="Enter token number, e.g. OPD001"
          value={tokenNumber}
          disabled={loading}
          autoComplete="off"
          onChange={(event) => {
            setTokenNumber(
              event.target.value,
            );

            setResult(null);
            setErrorMessage("");
          }}
        />

        <button
          style={{
            ...button,
            opacity: loading
              ? 0.7
              : 1,
          }}
          type="submit"
          disabled={loading}
        >
          {loading
            ? "Verifying..."
            : "Verify Token"}
        </button>

        <button
          style={qrButton}
          type="button"
          disabled={loading}
          onClick={toggleScanner}
        >
          {scannerOpen
            ? "Close Scanner"
            : "Scan QR"}
        </button>
      </form>

      {scannerOpen && (
        <div style={scannerBox}>
          <div style={scannerHeader}>
            <div>
              <h2 style={scannerTitle}>
                Scan Token QR
              </h2>

              <p style={scannerText}>
                Place the patient's QR
                code inside the camera
                frame.
              </p>
            </div>

            <button
              style={closeButton}
              type="button"
              onClick={closeScanner}
            >
              ×
            </button>
          </div>

          <div id="qr-reader" />
        </div>
      )}

      {errorMessage && (
        <div style={errorBox}>
          <strong>
            Verification failed
          </strong>

          <div style={messageText}>
            {errorMessage}
          </div>
        </div>
      )}

      {result && (
        <div style={successBox}>
          <div style={successHeader}>
            <div style={successIcon}>
              ✓
            </div>

            <div>
              <h2 style={resultTitle}>
                Patient Verified
              </h2>

              <p style={resultSubtitle}>
                This token belongs to the
                patient shown below.
              </p>
            </div>
          </div>

          <div style={resultGrid}>
            <ResultItem
              label="Token"
              value={result.tokenCode}
            />

            <ResultItem
              label="Patient"
              value={result.patientName}
            />

            <ResultItem
              label="Phone"
              value={
                result.patientPhone ||
                "-"
              }
            />

            <ResultItem
              label="Hospital"
              value={
                result.hospital || "-"
              }
            />

            <ResultItem
              label="Department"
              value={
                result.department || "-"
              }
            />

            <ResultItem
              label="Status"
              value={result.status}
            />

            <ResultItem
              label="Current Queue"
              value={
                result.currentQueue ??
                "-"
              }
            />

            <ResultItem
              label="People Ahead"
              value={
                result.peopleAhead ??
                "-"
              }
            />

            <ResultItem
              label="Estimated Waiting"
              value={
                result.estimatedTime ||
                "-"
              }
            />
          </div>
        </div>
      )}
    </div>
  );
}

function ResultItem({
  label,
  value,
}) {
  return (
    <div style={resultItem}>
      <div style={resultLabel}>
        {label}
      </div>

      <div style={resultValue}>
        {String(value ?? "-")}
      </div>
    </div>
  );
}

const page = {
  width: "100%",
};

const headingSection = {
  marginBottom: "24px",
};

const heading = {
  margin: 0,
  color: "#111827",
};

const subtitle = {
  color: "#6b7280",
  marginTop: "8px",
  marginBottom: 0,
};

const card = {
  background: "#ffffff",
  padding: "20px",
  borderRadius: "16px",
  display: "flex",
  gap: "12px",
  alignItems: "center",
  flexWrap: "wrap",
  boxShadow:
    "0 4px 16px rgba(15, 23, 42, 0.04)",
};

const input = {
  flex: "1 1 360px",
  minWidth: 0,
  padding: "13px 14px",
  border: "1px solid #dbe2ea",
  borderRadius: "10px",
  fontSize: "14px",
  outline: "none",
};

const button = {
  background: "#2563eb",
  color: "#ffffff",
  border: "none",
  padding: "13px 18px",
  borderRadius: "10px",
  cursor: "pointer",
  fontWeight: 600,
};

const qrButton = {
  background: "#16a34a",
  color: "#ffffff",
  border: "none",
  padding: "13px 18px",
  borderRadius: "10px",
  cursor: "pointer",
  fontWeight: 600,
};

const scannerBox = {
  background: "#ffffff",
  padding: "20px",
  borderRadius: "16px",
  marginTop: "20px",
  width: "100%",
  maxWidth: "560px",
  boxShadow:
    "0 4px 16px rgba(15, 23, 42, 0.06)",
};

const scannerHeader = {
  display: "flex",
  alignItems: "flex-start",
  justifyContent: "space-between",
  gap: "16px",
  marginBottom: "16px",
};

const scannerTitle = {
  margin: 0,
  fontSize: "18px",
  color: "#111827",
};

const scannerText = {
  margin: "6px 0 0",
  fontSize: "13px",
  color: "#6b7280",
};

const closeButton = {
  width: "34px",
  height: "34px",
  borderRadius: "50%",
  border: "none",
  background: "#f3f4f6",
  color: "#374151",
  cursor: "pointer",
  fontSize: "22px",
  lineHeight: 1,
};

const successBox = {
  background: "#f0fdf4",
  color: "#166534",
  padding: "22px",
  borderRadius: "16px",
  border: "1px solid #bbf7d0",
  marginTop: "24px",
};

const successHeader = {
  display: "flex",
  alignItems: "center",
  gap: "12px",
  marginBottom: "18px",
};

const successIcon = {
  width: "42px",
  height: "42px",
  borderRadius: "50%",
  background: "#16a34a",
  color: "#ffffff",
  display: "grid",
  placeItems: "center",
  fontSize: "22px",
  fontWeight: "bold",
};

const resultTitle = {
  margin: 0,
  color: "#166534",
};

const resultSubtitle = {
  margin: "4px 0 0",
  color: "#4b7b5d",
  fontSize: "13px",
};

const resultGrid = {
  display: "grid",
  gridTemplateColumns:
    "repeat(auto-fit, minmax(190px, 1fr))",
  gap: "12px",
};

const resultItem = {
  background: "#ffffff",
  border: "1px solid #dcfce7",
  borderRadius: "12px",
  padding: "14px",
};

const resultLabel = {
  color: "#6b7280",
  fontSize: "12px",
  marginBottom: "5px",
};

const resultValue = {
  color: "#111827",
  fontWeight: 600,
  overflowWrap: "anywhere",
};

const errorBox = {
  background: "#fef2f2",
  color: "#991b1b",
  padding: "18px",
  borderRadius: "14px",
  border: "1px solid #fecaca",
  marginTop: "20px",
};

const messageText = {
  marginTop: "5px",
};

export default VerifyPatient;