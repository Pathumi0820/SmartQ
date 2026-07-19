function StatCard({ title, value }) {
  return (
    <div style={{
      background: "#fff",
      padding: "22px",
      borderRadius: "14px",
      boxShadow: "0 4px 12px rgba(0,0,0,0.05)"
    }}>
      <p>{title}</p>
      <h2>{value}</h2>
    </div>
  );
}

export default StatCard;