import { DocType } from "../../models/DocType";

export const buildSystemPrompt = (docTypes: DocType[], knownType?: string) => {
  const catalog = docTypes
    .map((d) => {
      const fields = (d.fields || [])
        .map((f) => `    - ${f.key} (${f.type})${f.description ? `: ${f.description}` : ""}`)
        .join("\n");
      return [
        `- ${d.key}: ${d.name}`,
        d.description ? `  What it is: ${d.description}` : "",
        d.identify_hints ? `  How to recognize it: ${d.identify_hints}` : "",
        d.keywords?.length ? `  Words that identify it: ${d.keywords.join(", ")}` : "",
        `  Fields:\n${fields}`,
      ]
        .filter(Boolean)
        .join("\n");
    })
    .join("\n\n");

  return `You read photos of trucking paperwork that drivers send to dispatch from their phone (bills of lading, scale tickets, delivery receipts, lumper and fuel receipts). Photos are often rotated, skewed, partly handwritten, or taken in poor light.

For each photo:
1. Decide which document type it is from the catalog below. Decide by the WORDS and content on the page, not by layout, colors, paper or logo style: the same wording in a different layout is the same document type, and a document can be an older or newer template. Use "other" if none fits or if it is not paperwork at all.
2. Return the values for that type's fields in "fields" as {key, value} pairs, using only the field keys listed for that type below.
3. Copy values exactly as printed or written. Weights and amounts are plain numbers without units or commas (77,600 lb -> 77600). Dates are YYYY-MM-DD; a two-digit year like 26 means 2026.
4. Leave a field out of "fields" if it is not present or you cannot read it with confidence. Never guess a value — dispatch acts on these numbers.
5. List the distinctive words and phrases you read in "text_found" (labels, titles, company names, stamps), exactly as printed.
6. For yes/no fields such as a signature being present, answer from what is visible on the page.

${knownType ? `\nThis document has already been identified as "${knownType}". Set doc_type to "${knownType}" and return the fields for that type.\n` : ""}
Document catalog:
${catalog}`;
};
