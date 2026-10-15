// Classification by the WORDS on a document, independent of layout, color or photo angle.

export const normalizeText = (text: string): string =>
  ` ${(text || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim()} `;

export const cleanKeywords = (input: any): string[] => {
  if (!Array.isArray(input)) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of input) {
    const word = String(raw ?? "").trim().slice(0, 60);
    const key = normalizeText(word);
    if (word && key.trim() && !seen.has(key)) {
      seen.add(key);
      out.push(word);
    }
  }
  return out.slice(0, 100);
};

export interface KeywordType {
  key: string;
  keywords?: string[] | null;
}

export interface KeywordHit {
  key: string;
  matched: string[];
}

// Whole-word / whole-phrase match of each keyword inside the words found on the page
export const scoreKeywords = (textFound: string[], extraText: string | null, types: KeywordType[]): KeywordHit[] => {
  const corpus = normalizeText([...(textFound || []), extraText || ""].join(" "));
  return types
    .map((t) => ({
      key: t.key,
      matched: (t.keywords || []).filter((kw) => {
        const n = normalizeText(kw);
        return n.trim() !== "" && corpus.includes(n);
      }),
    }))
    .filter((h) => h.matched.length > 0)
    .sort((a, b) => b.matched.length - a.matched.length);
};

export const MIN_HITS_TO_OVERRIDE = 2;
export const MIN_HITS_TO_BOOST = 3;
export const LOW_CONFIDENCE = 0.7;

export interface Decision {
  doc_type: string;
  confidence: number;
  classified_by: "ai" | "keywords" | "ai+keywords";
  matched_keywords: string[];
  // set when the type changed and fields must be re-read for the new type
  needsReread: boolean;
}

// The AI's answer stays unless it was unsure/"other" and the words clearly point to one type.
export const decideDocType = (
  ai: { doc_type: string; confidence: number },
  hits: KeywordHit[],
): Decision => {
  const top = hits[0];
  const tie = hits.length > 1 && hits[1].matched.length === top?.matched.length;
  const aiHit = hits.find((h) => h.key === ai.doc_type);

  if (aiHit && aiHit.matched.length >= MIN_HITS_TO_BOOST) {
    return {
      doc_type: ai.doc_type,
      confidence: Math.max(ai.confidence, 0.9),
      classified_by: "ai+keywords",
      matched_keywords: aiHit.matched,
      needsReread: false,
    };
  }

  const aiUnsure = ai.doc_type === "other" || ai.confidence < LOW_CONFIDENCE;
  if (aiUnsure && top && !tie && top.key !== ai.doc_type && top.matched.length >= MIN_HITS_TO_OVERRIDE) {
    return {
      doc_type: top.key,
      confidence: Math.max(0.75, Math.min(0.95, 0.6 + top.matched.length * 0.1)),
      classified_by: "keywords",
      matched_keywords: top.matched,
      needsReread: true,
    };
  }

  return {
    doc_type: ai.doc_type,
    confidence: ai.confidence,
    classified_by: aiHit ? "ai+keywords" : "ai",
    matched_keywords: aiHit?.matched || [],
    needsReread: false,
  };
};

const STOP_WORDS = new Set(
  "the and for with from this that date time page total your you are was not all any per our has have will can may use".split(" "),
);

// Words worth suggesting as keywords: common on documents of this type, rare on other types
export const suggestKeywords = (
  typeDocs: string[][],
  otherDocs: string[][],
  existing: string[],
  options: { minDocs?: number; maxOtherShare?: number; limit?: number } = {},
): { word: string; docs: number }[] => {
  const { minDocs = 2, maxOtherShare = 0.3, limit = 30 } = options;
  const known = new Set(existing.map((k) => normalizeText(k)));
  const countDocs = (docs: string[][]) => {
    const counts = new Map<string, { word: string; docs: number }>();
    docs.forEach((words) => {
      const seen = new Set<string>();
      for (const w of words || []) {
        const n = normalizeText(w).trim();
        if (!n || seen.has(n)) continue;
        seen.add(n);
        const entry = counts.get(n) || { word: String(w).trim(), docs: 0 };
        entry.docs += 1;
        counts.set(n, entry);
      }
    });
    return counts;
  };
  const mine = countDocs(typeDocs);
  const others = countDocs(otherDocs);

  return [...mine.entries()]
    .filter(([n, v]) => {
      if (v.docs < minDocs || known.has(` ${n} `)) return false;
      if (n.length < 3 || /^[0-9 ]+$/.test(n) || STOP_WORDS.has(n)) return false;
      const otherShare = otherDocs.length ? (others.get(n)?.docs || 0) / otherDocs.length : 0;
      return otherShare <= maxOtherShare;
    })
    .map(([, v]) => v)
    .sort((a, b) => b.docs - a.docs)
    .slice(0, limit);
};
