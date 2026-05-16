import { apiFetch } from "./httpClient";

function cleanQuery(query) {
  const out = {};

  Object.entries(query || {}).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    if (typeof value === "string" && value.trim() === "") return;

    out[key] = value;
  });

  return out;
}

function buildQueryString(params) {
  const queryString = params.toString();
  return queryString ? `?${queryString}` : "";
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

  const res = await apiFetch(
    `/api/Admin/specialists${buildQueryString(params)}`,
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

export async function rejectSpecialist(id, payload) {
  return apiFetch(`/api/Admin/specialists/${id}/reject`, {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

export async function updateLicenseValidity(id, payload) {
  return apiFetch(`/api/Admin/specialists/${id}/license-validity`, {
    method: "PUT",
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

  const res = await apiFetch(`/api/Admin/clients${buildQueryString(params)}`);
  const payload = res?.data ?? res;

  return {
    ...payload,
    items: (payload?.items ?? []).map(normalizeUser),
  };
}

export async function getUser(id) {
  const res = await apiFetch(`/api/Admin/clients/${id}`);
  const payload = res?.data?.data ?? res?.data ?? res;

  return {
    ...payload,
    appointments: payload?.appointments ?? [],
  };
}

export async function listOrders(query = {}) {
  const params = new URLSearchParams();
  const cleaned = cleanQuery(query);

  if (cleaned.status) {
    params.set("status", cleaned.status);
  }

  if (cleaned.createdFrom) {
    params.set("fromDate", cleaned.createdFrom);
  }

  if (cleaned.createdTo) {
    params.set("toDate", cleaned.createdTo);
  }

  if (cleaned.page) {
    params.set("page", String(cleaned.page));
  }

  if (cleaned.pageSize) {
    params.set("pageSize", String(Math.min(cleaned.pageSize, 100)));
  }

  const res = await apiFetch(
    `/api/Admin/appointments${buildQueryString(params)}`,
  );

  const payload = res?.data?.data ?? res?.data ?? res;

  return {
    items: (payload?.items ?? []).map(normalizeOrderListItem),
    total: payload?.totalCount ?? payload?.total ?? 0,
    page: payload?.page ?? 1,
    pageSize: payload?.pageSize ?? 20,
  };
}

export async function getOrder(id) {
  const res = await apiFetch(`/api/Admin/appointments/${id}`);
  const payload = res?.data?.data ?? res?.data ?? res;

  return normalizeOrderDetails(payload);
}

export async function getAppointmentReview(appointmentId) {
  const res = await apiFetch(
    `/api/Client/appointments/${appointmentId}/review`,
  );

  return res?.data?.data ?? res?.data ?? res;
}

export async function getAdminStats() {
  const res = await apiFetch("/api/Admin/dashboard/stats");

  return res?.data?.data ?? res?.data ?? res;
}

function normalizeSpecialist(item) {
  if (!item) return item;

  const rawStatus = item.status ?? item.verificationStatus;

  const isSuspended =
    item.isSuspended === true ||
    item.is_suspended === true ||
    item.isActive === false ||
    item.is_active === false ||
    String(rawStatus).toUpperCase() === "SUSPENDED";

  return {
    ...item,
    id: item.id ?? item.specialistId,
    status: isSuspended
      ? "SUSPENDED"
      : rawStatus
        ? String(rawStatus).toUpperCase()
        : undefined,
    verificationStatus: isSuspended ? "SUSPENDED" : item.verificationStatus,
    isSuspended,
    isActive: isSuspended ? false : item.isActive,
    specialization: item.specialization ?? item.professionalTitle,
    licenseValidUntil:
      item.licenseValidUntil ??
      item.license_valid_until ??
      item.qualification?.licenseValidUntil ??
      item.qualification?.license_valid_until ??
      null,
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

function normalizeOrderListItem(item) {
  return {
    ...item,
    id: item?.id ?? item?.appointmentId,
    appointmentId: item?.appointmentId ?? item?.id,
    createdAt: item?.createdAt ?? item?.createdDate ?? item?.created_at ?? null,
    status: item?.status ?? "",
    totalPrice: item?.totalPrice ?? item?.price ?? 0,
    contactName: item?.contactName ?? "",
    specialistName: item?.specialistName ?? "",
  };
}

function normalizeOrderDetails(payload) {
  if (!payload) return payload;

  return {
    ...payload,

    id: payload.appointmentId ?? payload.id,
    appointmentId: payload.appointmentId ?? payload.id,

    contactName:
      payload.contactName ??
      payload.clientName ??
      payload.customerName ??
      payload.fullName ??
      "—",

    contactEmail:
      payload.contactEmail ??
      payload.clientEmail ??
      payload.customerEmail ??
      payload.email ??
      payload.client?.email ??
      payload.client?.user?.email ??
      "—",

    contactPhoneNumber:
      payload.contactPhoneNumber ??
      payload.contactPhone ??
      payload.phoneNumber ??
      payload.phone ??
      "—",

    serviceName:
      payload.serviceName ??
      payload.serviceTypeName ??
      payload.service?.name ??
      "—",

    specialistId:
      payload.specialistId ??
      payload.specialist?.specialistId ??
      payload.specialist?.id ??
      null,

    specialistName: getSpecialistName(payload),

    totalPrice:
      payload.totalPrice ?? payload.price ?? payload.totalAmount ?? null,

    clientNotes:
      payload.clientNotes ?? payload.description ?? payload.notes ?? "",

    createdAt:
      payload.createdAt ??
      payload.createdDate ??
      payload.created_at ??
      payload.scheduledStart ??
      null,

    status: payload.status ?? payload.appointmentStatus ?? "",
  };
}

function getSpecialistName(payload) {
  if (payload.specialistName && payload.specialistName !== "-") {
    return payload.specialistName;
  }

  if (payload.specialistFullName && payload.specialistFullName !== "-") {
    return payload.specialistFullName;
  }

  const firstName = payload.specialist?.firstName ?? "";
  const lastName = payload.specialist?.lastName ?? "";
  const fullName = `${firstName} ${lastName}`.trim();

  return (
    fullName ||
    payload.specialist?.name ||
    payload.specialist?.fullName ||
    "—"
  );
}