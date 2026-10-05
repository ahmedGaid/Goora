// Run: node --test supabase/functions/_shared/
// Same vectors as test/unit/matching_vectors_test.dart.
import { readFileSync } from "node:fs";
import { deepStrictEqual } from "node:assert";
import { test } from "node:test";
import { matchGroups } from "./matching.ts";
import type { Group, Seeker } from "./matching.ts";

interface Case {
  name: string;
  seeker: Seeker;
  groups: Group[];
  expect: {
    main: string | null;
    mainScore: number | null;
    mainReasons: string[];
    returnMatch: string | null;
    alternatives: [string, number][];
  };
}

const fixtureUrl = new URL("../../../test/fixtures/matching_vectors.json", import.meta.url);
const { cases } = JSON.parse(readFileSync(fixtureUrl, "utf8")) as { cases: Case[] };

for (const c of cases) {
  test(c.name, () => {
    const r = matchGroups(c.seeker, c.groups);
    deepStrictEqual(
      {
        main: r.main?.groupId ?? null,
        mainScore: r.main?.score ?? null,
        mainReasons: r.main?.reasons.map((x) => x.kind) ?? [],
        returnMatch: r.returnMatch?.groupId ?? null,
        alternatives: r.alternatives.map((a) => [a.groupId, a.score]),
      },
      c.expect,
    );
  });
}
