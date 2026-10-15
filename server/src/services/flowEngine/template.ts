import { getPath } from "./evaluate";

const formatValue = (value: any): string => {
  if (value === undefined || value === null || value === "") return "—";
  if (typeof value === "number") return value.toLocaleString("en-US");
  if (typeof value === "boolean") return value ? "yes" : "no";
  return String(value);
};

// Renders "Gross {{doc.fields.gross_lb}} lb" against the flow context
export const renderTemplate = (template: string, context: any): string =>
  (template || "").replace(/\{\{\s*([\w.]+)\s*\}\}/g, (_, path) => formatValue(getPath(context, path)));
