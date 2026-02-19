import { apiFetch } from "./httpClient";

export async function loginAdmin(email, password) {
  // DOCZELOWO:
  // return apiFetch("/admin/auth/login", {
  //   method: "POST",
  //   body: JSON.stringify({ email, password }),
  // });

  // MOCK:
  if (email === "admin@admin.pl" && password === "admin123") {
    const fakeToken = "FAKE_ADMIN_JWT_TOKEN";
    const admin = {
      id: "admin-1",
      email,
      role: "ADMIN",
    };

    // zapisujemy token jak backend by to zrobił
    localStorage.setItem("admin_token", fakeToken);
    localStorage.setItem("admin_user", JSON.stringify(admin));

    return Promise.resolve({ accessToken: fakeToken, admin });
  }

  return Promise.reject(new Error("Nieprawidłowy email lub hasło"));
}

export function logoutAdmin() {
  localStorage.removeItem("admin_token");
  localStorage.removeItem("admin_user");
}

export function getLoggedAdmin() {
  const raw = localStorage.getItem("admin_user");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}
