const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:5016";

export async function loginAdmin(email, password) {
  const res = await fetch(`${API_BASE_URL}/api/Auth/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Błąd logowania: ${text || res.statusText}`);
  }

  const data = await res.json();
  const payload = data?.data ?? data;
  const accessToken = payload?.accessToken;
  const user = payload?.user;

  if (!accessToken || !user) {
    throw new Error("Nieprawidłowa odpowiedź serwera");
  }

  if (user.userType !== "admin") {
    throw new Error("To konto nie ma dostępu do panelu administratora");
  }

  localStorage.setItem("admin_token", accessToken);
  localStorage.setItem("admin_user", JSON.stringify(user));

  return payload;
}

export function logoutAdmin() {
  localStorage.removeItem("admin_token");
  localStorage.removeItem("admin_user");
}

export function getAdminUser() {
  const raw = localStorage.getItem("admin_user");
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function getLoggedAdmin() {
  return getAdminUser();
}