// Loads test/fixtures/<name>_vectors.json for the node --test mirrors of
// test/unit/daily_vectors_test.dart.
import { readFileSync } from "node:fs";

export function loadCases<T>(name: string): T[] {
  const url = new URL(`../../../test/fixtures/${name}_vectors.json`, import.meta.url);
  return (JSON.parse(readFileSync(url, "utf8")) as { cases: T[] }).cases;
}
