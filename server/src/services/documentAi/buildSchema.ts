import { DocField, DocType } from "../../models/DocType";

// The structured-output schema must stay free of unions (nullable types, anyOf): the API rejects
// schemas with many of them ("too many parameters with union types"). So field values come back as
// a list of {key, value} text pairs, and the server converts each value to its real type.
// A field that is absent or unreadable is simply left out of the list.
export const buildExtractionSchema = (docTypes: DocType[]) => {
  const fieldKeys = Array.from(new Set(docTypes.flatMap((d) => (d.fields || []).map((f) => f.key))));

  return {
    type: "object",
    properties: {
      is_document: {
        type: "boolean",
        description: "True if the image shows paperwork (any document, ticket or receipt).",
      },
      doc_type: {
        type: "string",
        enum: [...docTypes.map((d) => d.key), "other"],
      },
      confidence: {
        type: "number",
        description: "0 to 1. How sure you are about doc_type.",
      },
      image_quality: {
        type: "string",
        enum: ["good", "poor", "unreadable"],
        description: "poor = blurry/dark/cut off but partly readable; unreadable = key text cannot be read.",
      },
      notes: {
        type: "string",
        description:
          "Short note for dispatch about anything unusual (handwritten changes, missing pages, stamps). Empty string if nothing.",
      },
      text_found: {
        type: "array",
        items: { type: "string" },
        description:
          "Up to 30 distinctive words or short phrases printed on the document (titles, company names, field labels like 'STEER AXLE', 'CONSIGNEE', stamps). Copy them as printed. Skip numbers and personal data.",
      },
      fields: {
        type: "array",
        description:
          "The values read from the document, only for fields of the chosen doc_type. Leave out any field that is not present or not readable.",
        items: {
          type: "object",
          properties: {
            key: { type: "string", enum: fieldKeys.length ? fieldKeys : ["none"] },
            value: {
              type: "string",
              description: "The value as text. Numbers without units or commas. Dates as YYYY-MM-DD. Yes/no fields as true or false.",
            },
          },
          required: ["key", "value"],
          additionalProperties: false,
        },
      },
    },
    required: ["is_document", "doc_type", "confidence", "image_quality", "notes", "text_found", "fields"],
    additionalProperties: false,
  };
};

const YES = new Set(["true", "yes", "y", "1", "signed", "present"]);
const NO = new Set(["false", "no", "n", "0", "unsigned", "none"]);

const coerce = (field: DocField, raw: string): any => {
  const text = String(raw ?? "").trim();
  if (!text || /^(null|n\/a|na|unknown|unreadable|—|-)$/i.test(text)) return null;
  switch (field.type) {
    case "number": {
      const n = Number(text.replace(/[$,\s]|lbs?\.?$/gi, ""));
      return Number.isFinite(n) ? n : null;
    }
    case "boolean": {
      const t = text.toLowerCase();
      return YES.has(t) ? true : NO.has(t) ? false : null;
    }
    default:
      return text;
  }
};

// Turns the model's [{key, value}] list into { key: typedValue } for the chosen document type.
// Every field of the type is present in the result (null when it was not read).
export const parseFields = (
  docType: DocType | undefined,
  pairs: { key: string; value: string }[] | undefined,
): Record<string, any> => {
  if (!docType) return {};
  const byKey = new Map((pairs || []).map((p) => [p.key, p.value]));
  const out: Record<string, any> = {};
  for (const field of docType.fields || []) {
    out[field.key] = byKey.has(field.key) ? coerce(field, byKey.get(field.key) as string) : null;
  }
  return out;
};
