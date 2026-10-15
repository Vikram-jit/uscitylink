// Run: npx ts-node scripts/test-keywords.ts
import assert from "assert";
import { cleanKeywords, decideDocType, scoreKeywords, suggestKeywords } from "../src/services/documentAi/keywords";

const types = [
  { key: "scale_ticket", keywords: ["CAT Scale", "steer axle", "drive axle", "gross weight", "weigh number"] },
  { key: "bol_pickup", keywords: ["bill of lading", "shipper", "consignee", "seal"] },
];

// different layout, same words
const text = ["Certified Automated Truck SCALE", "CAT SCALE COMPANY", "STEER AXLE 11740 lb", "DRIVE-AXLE 31880 lb", "*GROSS WEIGHT 77600"];
const hits = scoreKeywords(text, null, types);
assert.strictEqual(hits[0].key, "scale_ticket");
assert.strictEqual(hits[0].matched.length, 4, "punctuation/case ignored, phrases matched");

// AI unsure -> keywords win
let d = decideDocType({ doc_type: "other", confidence: 0.3 }, hits);
assert.strictEqual(d.doc_type, "scale_ticket"); assert.strictEqual(d.classified_by, "keywords"); assert.ok(d.needsReread);
// AI confident and different -> AI stays
d = decideDocType({ doc_type: "bol_pickup", confidence: 0.92 }, hits);
assert.strictEqual(d.doc_type, "bol_pickup"); assert.strictEqual(d.classified_by, "ai");
// AI right -> boosted
d = decideDocType({ doc_type: "scale_ticket", confidence: 0.55 }, hits);
assert.strictEqual(d.classified_by, "ai+keywords"); assert.ok(d.confidence >= 0.9); assert.ok(!d.needsReread);
// one stray word is not enough to override
d = decideDocType({ doc_type: "other", confidence: 0.4 }, scoreKeywords(["shipper"], null, types));
assert.strictEqual(d.doc_type, "other");
// whole words only: "sealed" must not match "seal"... but "seal" alone does
assert.strictEqual(scoreKeywords(["resealed"], null, types).length, 0);
assert.strictEqual(scoreKeywords(["SEAL #123"], null, types)[0].key, "bol_pickup");
// ties are not guessed
d = decideDocType({ doc_type: "other", confidence: 0.2 }, scoreKeywords(["steer axle drive axle shipper consignee"], null, types));
assert.strictEqual(d.doc_type, "other");

assert.deepStrictEqual(cleanKeywords([" Gross Weight ", "gross  weight", "", "Seal"]), ["Gross Weight", "Seal"]);

const s = suggestKeywords(
  [["CAT Scale", "Weigh Number", "Date", "12345"], ["CAT Scale", "Weigh Number", "Fee"]],
  [["Date", "Shipper"], ["Date", "Consignee"]],
  [],
);
assert.deepStrictEqual(s.map((x) => x.word), ["CAT Scale", "Weigh Number"], "common here, rare elsewhere, no numbers/stop words");

console.log("✅ keyword checks passed");
