import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { loginAdmin } from "./api/adminAuthApi";
import logo from "/src/assets/logo.png"; 
import "./styles/login.css";

function LoginPage() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");

    if (!email || !password) {
      setError("Podaj email i hasło");
      return;
    }

    try {
      setLoading(true);
      await loginAdmin(email, password);
      navigate("/dashboard");
    } catch (e) {
      setError(e.message || "Błąd logowania");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login3">
      <div className="login3-hero">
        <div className="login3-logo">
          <img src={logo} alt="Logo" />
        </div>

        <h1 className="login3-title">Panel administratora</h1>
        <p className="login3-sub">
          Zarządzaj specjalistami, użytkownikami i zamówieniami.
        </p>
      </div>

      <form className="login3-card" onSubmit={handleSubmit}>
        <h2 className="login3-cardTitle">Zaloguj się</h2>

        {error && <p className="login3-error">{error}</p>}

        <div className="login3-field">
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>

        <div className="login3-field">
          <input
            type="password"
            placeholder="Hasło"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>

        <button className="login3-btn" disabled={loading} type="submit">
          {loading ? "Logowanie..." : "Zaloguj"}
        </button>

      </form>
    </div>
  );
}

export default LoginPage;
