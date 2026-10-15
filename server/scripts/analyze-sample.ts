// Run: npx ts-node scripts/analyze-sample.ts <image-or-pdf> [more files...]
// Prints what the document AI reads from each file, using the doc types in the database.
import fs from "fs";
import path from "path";
import { analyzePreparedFile, getActiveDocTypes } from "../src/services/documentAi/analyzeDocument";
import { getAnalyzableKind, prepareBuffer } from "../src/services/documentAi/fileSource";
import { primarySequelize } from "../src/sequelize";

const main = async () => {
  const files = process.argv.slice(2);
  if (!files.length) {
    console.error("Usage: npx ts-node scripts/analyze-sample.ts <file> [file...]");
    process.exit(1);
  }
  const docTypes = await getActiveDocTypes();
  console.log(`Using ${docTypes.length} doc types: ${docTypes.map((d) => d.key).join(", ")}\n`);

  for (const file of files) {
    const kind = getAnalyzableKind(file);
    if (!kind) {
      console.log(`${file}: skipped (not an image or PDF)`);
      continue;
    }
    const prepared = await prepareBuffer(fs.readFileSync(file), kind);
    const result = await analyzePreparedFile(prepared, { docTypes });
    console.log(`── ${path.basename(file)}`);
    console.log(JSON.stringify(result, null, 2), "\n");
  }
  await primarySequelize.close();
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
