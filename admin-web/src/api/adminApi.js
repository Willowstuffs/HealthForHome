import { apiFetch } from "./httpClient";

/**
 * API dla panelu admina (mock -> backend-ready)
 * - listSpecialists(query)
 * - getSpecialist(id)
 * - approveSpecialist(id)
 * - rejectSpecialist(id, payload)
 */

export async function listSpecialists(query) {
  // Docelowo:
  // return apiFetch(`/admin/specialists?${new URLSearchParams(cleanQuery(query))}`);
  return mockListSpecialists(query);
}

export async function getSpecialist(id) {
  // Docelowo:
  // return apiFetch(`/admin/specialists/${id}`);
  return mockGetSpecialist(id);
}

export async function approveSpecialist(id) {
  // Docelowo:
  // return apiFetch(`/admin/specialists/${id}/approve`, { method: "POST" });
  return mockApprove(id);
}

export async function rejectSpecialist(id, payload) {
  // Docelowo:
  // return apiFetch(`/admin/specialists/${id}/reject`, { method: "POST", body: JSON.stringify(payload) });
  return mockReject(id, payload);
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

/*  MOCK  */

let DB = [
  {
    id: "1",
    firstName: "Anna",
    lastName: "Nowak",
    email: "anna.nowak@test.pl",
    specialization: "PIELEGNIARKA",
    status: "PENDING",
    nip: "1234567890",
    registryBookNumber: "KR-10001",
    voivodeship: "Mazowieckie",
    city: "Warszawa",
    address: "ul. Testowa 1",
    licenseNumber: "PWZ1234567",
    createdAt: "2026-01-01T10:00:00.000Z",
    licenseStatus: "VALID",
    licenseValidUntil: "2027-12-31",
  },
  {
    id: "2",
    firstName: "Jan",
    lastName: "Kowalski",
    email: "jan.kowalski@test.pl",
    specialization: "FIZJOTERAPEUTA",
    status: "APPROVED",
    nip: "0987654321",
    registryBookNumber: "KR-10002",
    voivodeship: "Małopolskie",
    city: "Kraków",
    address: "ul. Testowa 2",
    licenseNumber: "PWZ7654321",
    createdAt: "2026-01-02T10:00:00.000Z",
    licenseStatus: "EXPIRED",
    licenseValidUntil: "2020-01-01",
  },
];
let USERS = [
  {
    id: "u1",
    firstName: "Kasia",
    lastName: "Wiśniewska",
    email: "kasia@test.pl",
    phone: "500600700",
    createdAt: "2026-01-10T09:00:00.000Z",
    ordersCount: 2,
    ordersTotalValue: 320,
  },
  {
    id: "u2",
    firstName: "Marek",
    lastName: "Kowalski",
    email: "marek@test.pl",
    phone: "501111222",
    createdAt: "2026-01-20T12:00:00.000Z",
    ordersCount: 0,
    ordersTotalValue: 0,
  },
];

function cleanQuery(query) {
  const out = {};
  Object.entries(query || {}).forEach(([k, v]) => {
    if (v === undefined || v === null) return;
    if (typeof v === "string" && v.trim() === "") return;
    out[k] = v;
  });
  return out;
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
