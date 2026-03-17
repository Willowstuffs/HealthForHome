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

export async function listSpecialists(query) {
  const params = new URLSearchParams();
  const cleaned = cleanQuery(query);

  if (cleaned.status) {
    params.set("verificationStatus", cleaned.status.toLowerCase());
  }

  if (cleaned.specialization) {
    params.set("specialization", cleaned.specialization);
  }

  if (cleaned.createdFrom) {
    params.set("registeredFrom", cleaned.createdFrom);
  }

  if (cleaned.createdTo) {
    params.set("registeredTo", cleaned.createdTo);
  }

  if (cleaned.sort) {
    params.set(
      "sortDescending",
      cleaned.sort === "CREATED_DESC" ? "true" : "false",
    );
  }

  if (cleaned.page) {
    params.set("page", String(cleaned.page));
  }

  if (cleaned.pageSize) {
    params.set("pageSize", String(cleaned.pageSize));
  }

  const queryString = params.toString();
  const res = await apiFetch(
    `/api/Admin/specialists${queryString ? `?${queryString}` : ""}`,
  );
  const payload = res?.data ?? res;

  return {
    ...payload,
    items: (payload?.items ?? []).map(normalizeSpecialist),
  };
}

export async function getSpecialist(id) {
  const res = await apiFetch(`/api/Admin/specialists/${id}`);
  const payload = res?.data ?? res;
  return normalizeSpecialist(payload);
}

export async function approveSpecialist(id) {
  return apiFetch(`/api/Admin/specialists/${id}/approve`, {
    method: "POST",
  });
}
export async function updateLicenseValidity(id, payload) {
  return apiFetch(`/api/Admin/specialists/${id}/license-validity`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}
export async function rejectSpecialist(id, payload) {
  return apiFetch(`/api/Admin/specialists/${id}/reject`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}
export async function suspendSpecialist(id) {
  return apiFetch(`/api/Admin/specialists/${id}/suspend`, {
    method: "POST",
  });
}

export async function unsuspendSpecialist(id) {
  return apiFetch(`/api/Admin/specialists/${id}/unsuspend`, {
    method: "POST",
  });
}
export async function listUsers(query) {
  const params = new URLSearchParams();
  const cleaned = cleanQuery(query);

  if (cleaned.q) {
    params.set("search", cleaned.q);
  }

  if (cleaned.createdFrom) {
    params.set("registeredFrom", cleaned.createdFrom);
  }

  if (cleaned.createdTo) {
    params.set("registeredTo", cleaned.createdTo);
  }

  if (cleaned.sort) {
    params.set(
      "sortDescending",
      cleaned.sort === "CREATED_DESC" ? "true" : "false",
    );
  }

  if (cleaned.page) {
    params.set("page", String(cleaned.page));
  }

  if (cleaned.pageSize) {
    params.set("pageSize", String(cleaned.pageSize));
  }

  const queryString = params.toString();
  const res = await apiFetch(
    `/api/Admin/clients${queryString ? `?${queryString}` : ""}`,
  );

  const payload = res?.data ?? res;

  return {
    ...payload,
    items: (payload?.items ?? []).map(normalizeUser),
  };
}

export async function getUser(id) {
  const res = await apiFetch(`/api/Admin/clients/${id}`);
  const payload = res?.data ?? res;
  return normalizeUser(payload);
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

function normalizeSpecialist(item) {
  if (!item) return item;

  const rawStatus = item.status ?? item.verificationStatus;

  return {
    ...item,
    id: item.id ?? item.specialistId,
    status: rawStatus ? String(rawStatus).toUpperCase() : undefined,
    specialization: item.specialization ?? item.professionalTitle,
  };
}
function normalizeUser(item) {
  if (!item) return item;

  return {
    ...item,
    id: item.id ?? item.clientId ?? item.userId,
    firstName: item.firstName ?? "",
    lastName: item.lastName ?? "",
    email: item.email ?? "",
    phone: item.phone ?? item.phoneNumber ?? "",
    createdAt: item.createdAt ?? item.registeredAt ?? item.registrationDate,
    ordersCount: item.ordersCount ?? item.totalOrders ?? item.appointmentsCount,
    ordersTotalValue:
      item.ordersTotalValue ?? item.totalOrdersValue ?? item.totalSpent,
  };
}

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
