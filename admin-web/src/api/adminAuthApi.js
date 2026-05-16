const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "https://h4h.makolino.com";

const TOKEN_KEY = "admin_token";
const USER_KEY = "admin_user";

export async function loginAdmin(email, password) {
  const res = await fetch(`${API_BASE_URL}/api/Auth/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const message = await getErrorMessage(res);
    throw new Error(`Błąd logowania: ${message}`);
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

  localStorage.setItem(TOKEN_KEY, accessToken);
  localStorage.setItem(USER_KEY, JSON.stringify(user));

  return payload;
}

export function logoutAdmin() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

export function getAdminUser() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;

  try {
    return JSON.parse(raw);
  } catch {
    localStorage.removeItem(USER_KEY);
    return null;
  }
}

export function getLoggedAdmin() {
  return getAdminUser();
}

async function getErrorMessage(res) {
  const text = await res.text().catch(() => "");

  return text || res.statusText || "Nieznany błąd";
}
