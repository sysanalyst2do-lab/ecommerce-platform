import { STATUS_LABELS, STATUS_COLORS } from "../types/order";

export function StatusBadge({ status }: { status: string }) {
  return (
    <span
      className="status-badge"
      style={{ backgroundColor: STATUS_COLORS[status] || "#6b7280" }}
    >
      {STATUS_LABELS[status] || status}
    </span>
  );
}
