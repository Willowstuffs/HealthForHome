import { apiFetch } from "./httpClient";

function cleanQuery(query) {
  const out = {};
  Object.entries(query || {}).forEach(([k, v]) => {
    if (v === undefined || v === null) return;
    if (typeof v === "string" && v.trim() === "") return;
    out[k] = v;
  });
  return out;
}

export async function listSpecialists() {
  return apiFetch(`/api/Admin/specialists`);
}

export async function getSpecialist(id) {
  return apiFetch(`/api/Admin/specialists/${id}`);
}

export async function approveSpecialist(id) {
  return apiFetch(`/api/Admin/specialists/${id}/approve`, {
    method: "POST",
  });
}

export async function rejectSpecialist(id, payload) {
  return apiFetch(`/api/Admin/specialists/${id}/reject`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}
export async function listUsers(query) {
  // Docelowo:
  // return apiFetch(`/admin/users?${new URLSearchParams(cleanQuery(query))}`);
  return mockListUsers(query);
}

export async function getUser(id) {
  // Docelowo:
  // return apiFetch(`/admin/users/${id}`);
  return mockGetUser(id);
}
export async function listOrders(query) {
  // Docelowo:
  // const params = new URLSearchParams();
  // if (query.status) params.set("status", query.status);
  // if (query.createdFrom) params.set("createdFrom", query.createdFrom);
  // if (query.createdTo) params.set("createdTo", query.createdTo);
  // if (query.sort) params.set("sort", query.sort);
  // if (query.page) params.set("page", String(query.page));
  // if (query.pageSize) params.set("pageSize", String(query.pageSize));
  // return apiFetch(`/admin/orders?${params.toString()}`);

  // MOCK:
  return mockListOrders(query);
}

export async function getOrder(id) {
  return mockGetOrder(id);
}

export async function getAdminStats() {
  return mockGetAdminStats();
}

function mockListSpecialists(query) {
  const q = cleanQuery(query);

  const page = Number(q.page || 1);
  const pageSize = Number(q.pageSize || 20);

  let items = [...DB];

  if (q.status) items = items.filter((x) => x.status === q.status);

  if (q.specialization) {
    items = items.filter((x) => x.specialization === q.specialization);
  }

  if (q.createdFrom) {
    const from = new Date(`${q.createdFrom}T00:00:00.000Z`);
    items = items.filter((x) => new Date(x.createdAt) >= from);
  }

  if (q.createdTo) {
    const to = new Date(`${q.createdTo}T23:59:59.999Z`);
    items = items.filter((x) => new Date(x.createdAt) <= to);
  }

  items.sort((a, b) => {
    const diff = new Date(a.createdAt) - new Date(b.createdAt);
    return q.sort === "CREATED_DESC" ? -diff : diff;
  });

  const total = items.length;

  const start = (page - 1) * pageSize;
  const paged = items.slice(start, start + pageSize);

  return Promise.resolve({ items: paged, total, page, pageSize });
}

function mockGetSpecialist(id) {
  const found = DB.find((x) => x.id === id);
  if (!found) return Promise.reject(new Error("NOT_FOUND"));
  return Promise.resolve(found);
}

function mockApprove(id) {
  DB = DB.map((x) => (x.id === id ? { ...x, status: "APPROVED" } : x));
  return Promise.resolve();
}

function mockReject(id, payload) {
  if (!payload?.reasonText) return Promise.reject(new Error("REASON_REQUIRED"));
  DB = DB.map((x) => (x.id === id ? { ...x, status: "REJECTED" } : x));
  return Promise.resolve();
}

/* MOCK USERS */
function mockListUsers(query) {
  const q = cleanQuery(query);

  const page = Number(q.page || 1);
  const pageSize = Number(q.pageSize || 20);

  let items = [...USERS];

  // search
  if (q.q) {
    const s = q.q.toLowerCase();
    items = items.filter((u) =>
      `${u.firstName} ${u.lastName} ${u.email}`.toLowerCase().includes(s),
    );
  }

  // date filters
  if (q.createdFrom) {
    const from = new Date(`${q.createdFrom}T00:00:00.000Z`);
    items = items.filter((u) => new Date(u.createdAt) >= from);
  }

  if (q.createdTo) {
    const to = new Date(`${q.createdTo}T23:59:59.999Z`);
    items = items.filter((u) => new Date(u.createdAt) <= to);
  }

  // sort
  items.sort((a, b) => {
    const diff = new Date(a.createdAt) - new Date(b.createdAt);
    return q.sort === "CREATED_ASC" ? diff : -diff;
  });

  const total = items.length;

  const start = (page - 1) * pageSize;
  const paged = items.slice(start, start + pageSize);

  return Promise.resolve({ items: paged, total, page, pageSize });
}

function mockGetUser(id) {
  const found = USERS.find((u) => u.id === id);
  if (!found) return Promise.reject(new Error("NOT_FOUND"));
  return Promise.resolve(found);
}

let ORDERS = [
  {
    id: "o1",
    userId: "u1",
    userName: "Kasia Wiśniewska",
    specialistId: "1",
    specialistName: "Anna Nowak",
    customerEmail: "marek@test.pl",
    customerPhone: "500600700",
    totalValue: 180,
    status: "NEW",
    createdAt: "2026-02-01T10:15:00.000Z",
    description: "Wizyta domowa",
  },
  {
    id: "o2",
    userId: "u1",
    userName: "Kasia Wiśniewska",
    customerEmail: "marek@test.pl",
    customerPhone: "501111222",
    specialistId: "2",
    specialistName: "Jan Kowalski",
    totalValue: 140,
    status: "DONE",
    createdAt: "2026-01-28T08:30:00.000Z",
    description: "Rehabilitacja",
  },
  {
    id: "o3",
    userId: "u2",
    userName: "Marek Kowalski",
    customerEmail: "marek@test.pl",
    customerPhone: "501111222",
    specialistId: "2",
    specialistName: "Jan Kowalski",
    totalValue: 220,
    status: "IN_PROGRESS",
    createdAt: "2026-02-02T12:00:00.000Z",
    description: "Konsultacja",
  },
];

function mockListOrders(query) {
  const q = cleanQuery(query);

  const page = Number(q.page || 1);
  const pageSize = Number(q.pageSize || 20);

  let items = [...ORDERS];

  if (q.status) items = items.filter((o) => o.status === q.status);

  if (q.createdFrom) {
    const from = new Date(`${q.createdFrom}T00:00:00.000Z`);
    items = items.filter((o) => new Date(o.createdAt) >= from);
  }

  if (q.createdTo) {
    const to = new Date(`${q.createdTo}T23:59:59.999Z`);
    items = items.filter((o) => new Date(o.createdAt) <= to);
  }

  items.sort((a, b) => {
    const diff = new Date(a.createdAt) - new Date(b.createdAt);
    return q.sort === "CREATED_ASC" ? diff : -diff;
  });

  const total = items.length;
  const start = (page - 1) * pageSize;
  const paged = items.slice(start, start + pageSize);

  return Promise.resolve({ items: paged, total, page, pageSize });
}

function mockGetOrder(id) {
  const found = ORDERS.find((o) => o.id === id);
  if (!found) return Promise.reject(new Error("NOT_FOUND"));
  return Promise.resolve(found);
}

function mockGetAdminStats() {
  // UWAGA: to jest mock – docelowo backend
  const usersTotal = typeof USERS !== "undefined" ? USERS.length : 0;
  const specialistsTotal = DB.length;
  const specialistsPending = DB.filter((s) => s.status === "PENDING").length;

  const ordersTotal = ORDERS.length;
  const ordersNew = ORDERS.filter((o) => o.status === "NEW").length;
  const ordersTotalValue = ORDERS.reduce(
    (sum, o) => sum + (Number(o.totalValue) || 0),
    0,
  );

  return Promise.resolve({
    usersTotal,
    specialistsTotal,
    specialistsPending,
    ordersTotal,
    ordersNew,
    ordersTotalValue,
  });
}
