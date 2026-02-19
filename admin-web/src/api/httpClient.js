const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000";

function getToken() {
  // Na razie mock (później backend zwróci token po logowaniu admina)
  return localStorage.getItem("admin_token");
}

export async function apiFetch(path, options = {}) {
  const token = getToken();

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`API error ${res.status}: ${text || res.statusText}`);
  }

  // backend czasem zwraca 204 No Content
  if (res.status === 204) return null;

  return res.json();
}
