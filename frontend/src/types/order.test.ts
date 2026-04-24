import { describe, expect, it } from "vitest";
import { STATUS_COLORS, STATUS_LABELS } from "./order";

describe("order status mappings", () => {
  it("contains labels for all expected statuses", () => {
    expect(STATUS_LABELS).toMatchObject({
      created: "Новый",
      paid: "Оплачен",
      processing: "В обработке",
      shipped: "Отгружен",
      delivered: "Доставлен",
      cancelled: "Отменён",
    });
  });

  it("keeps color mapping for each status", () => {
    const statuses = Object.keys(STATUS_LABELS);
    for (const status of statuses) {
      expect(STATUS_COLORS[status]).toBeTruthy();
    }
    expect(STATUS_COLORS.cancelled).toBe("#dc2626");
  });
});
