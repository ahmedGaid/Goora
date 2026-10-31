// Run: node --test "supabase/functions/_shared/*.test.ts"
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { canChooseNoCover } from "./no_cover.ts";

test("no ride stored: nothing to take the day off from", () => {
  strictEqual(canChooseNoCover(null), false);
});

test("a ride with a driver (planned or backup): refused", () => {
  strictEqual(canChooseNoCover({ driver_id: "u1" }), false);
});

test("a ride whose backup search found nobody: allowed", () => {
  strictEqual(canChooseNoCover({ driver_id: null }), true);
});
