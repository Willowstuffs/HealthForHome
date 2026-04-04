export function parseDateSafe(value) {
  if (!value) return null;

  if (value instanceof Date) return value;

  if (typeof value === "string") {
    // DD.MM.YYYY
    const dot = value.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
    if (dot) {
      const [, dd, mm, yyyy] = dot;
      return new Date(Number(yyyy), Number(mm) - 1, Number(dd));
    }

    // ISO / YYYY-MM-DD / datetime
    const d = new Date(value);
    if (!Number.isNaN(d.getTime())) return d;

    return null;
  }

  const d = new Date(value);
  if (!Number.isNaN(d.getTime())) return d;

  return null;
}

export function computeLicenseStatus(licenseStatus, licenseValidUntil) {
  const until = parseDateSafe(licenseValidUntil);
  if (!until) return licenseStatus || "UNKNOWN";

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  until.setHours(0, 0, 0, 0);

  if (until < today) return "EXPIRED";
  return licenseStatus || "UNKNOWN";
}
