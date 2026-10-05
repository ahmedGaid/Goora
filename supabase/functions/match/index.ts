// POST /functions/v1/match — matches the calling user (specs/002-commute-matching/contracts/match-function.md).
// Thin adapter: auth + data loading here, all rules in ../_shared/matching.ts.
import { createClient } from "npm:@supabase/supabase-js@2";
import { matchGroups } from "../_shared/matching.ts";
import type { Group, Seeker } from "../_shared/matching.ts";

interface MatchInput {
  seeker: (Seeker & { homeArea: string; workArea: string }) | null;
  groups: Group[];
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";
  const { data: auth, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !auth.user) return json({ error: "unauthorized" }, 401);

  const { data, error } = await admin.rpc("match_input", { p_user: auth.user.id });
  if (error) return json({ error: "match_input_failed" }, 500);
  const input = data as MatchInput;
  if (!input.seeker) return json({ error: "no_commute_profile" }, 409);

  const result = matchGroups(input.seeker, input.groups);
  if (result.main) return json({ ...result, waitlistPosition: null });

  const corridor = { origin_area: input.seeker.homeArea, destination_area: input.seeker.workArea };
  await admin.from("waitlist").upsert({ user_id: auth.user.id, ...corridor });
  const { data: queue } = await admin.from("waitlist").select("user_id, created_at").match(corridor)
    .order("created_at");
  const position = (queue ?? []).findIndex((row) => row.user_id === auth.user.id) + 1;
  return json({ main: null, returnMatch: null, alternatives: [], waitlistPosition: position });
});
