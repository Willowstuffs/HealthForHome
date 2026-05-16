const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "https://h4h.makolino.com";

const TOKEN_KEY = "admin_token";

function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export async function apiFetch(path, options = {}) {
  const token = getToken();

  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token && {
        Authorization: `Bearer ${token}`,
      }),
      ...options.headers,
    },
  });

  if (!res.ok) {
    throw new Error(await buildErrorMessage(res));
  }

  if (res.status === 204) {
    return null;
  }

  return res.json();
}

async function buildErrorMessage(res) {
  const text = await res.text().catch(() => "");

  return `API error ${res.status}: ${
    text || res.statusText || "Unknown error"
  }`;
}
