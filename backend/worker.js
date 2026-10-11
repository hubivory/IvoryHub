// Cloudflare Worker - Key Validation + GPT shared games list
// Deploy: npx wrangler deploy
// KV: npx wrangler kv:namespace create GAMES  (then set id in wrangler.toml)

const LOOTLABS_KEY = "YOUR_LOOTLABS_KEY_HERE";
const WORKINK_KEY = "YOUR_WORKINK_KEY_HERE";
// Optional shared secret for /gpt/games writes. Empty = open writes.
const GPT_WRITE_TOKEN = "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Ivory-Token",
};

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function normalizeGame(g) {
  const likes = Number(g.likes) || 0;
  const dislikes = Number(g.dislikes) || 0;
  const voters = {};
  if (g.voters && typeof g.voters === "object") {
    for (const [k, v] of Object.entries(g.voters)) {
      if (v === "like" || v === "dislike") voters[String(k)] = v;
    }
  }
  return {
    placeId: Number(g.placeId) || 0,
    gameId: Number(g.gameId) || 0,
    name: String(g.name || "Unknown").slice(0, 120),
    verdict: String(g.verdict || "?").slice(0, 80),
    checks: Math.max(1, Number(g.checks) || 1),
    likes: Math.max(0, likes),
    dislikes: Math.max(0, dislikes),
    voters,
    confirmed: g.confirmed === true,
    lastCheck: String(g.lastCheck || new Date().toISOString()).slice(0, 40),
    reporter: String(g.reporter || "?").slice(0, 40),
  };
}

async function loadList(env) {
  if (!env.GAMES) return { version: 1, updatedAt: new Date().toISOString(), games: [] };
  const raw = await env.GAMES.get("list");
  if (!raw) return { version: 1, updatedAt: new Date().toISOString(), games: [] };
  try {
    const data = JSON.parse(raw);
    if (!data || !Array.isArray(data.games)) return { version: 1, updatedAt: new Date().toISOString(), games: [] };
    return data;
  } catch {
    return { version: 1, updatedAt: new Date().toISOString(), games: [] };
  }
}

async function saveList(env, data) {
  data.version = 1;
  data.updatedAt = new Date().toISOString();
  if (env.GAMES) {
    await env.GAMES.put("list", JSON.stringify(data));
  }
  return data;
}

function mergeGames(existing, incoming) {
  const byPlace = new Map();
  for (const g of existing || []) {
    if (g && g.placeId != null) byPlace.set(Number(g.placeId), normalizeGame(g));
  }
  for (const g of incoming || []) {
    if (!g || !g.placeId) continue;
    const id = Number(g.placeId);
    const next = normalizeGame(g);
    const prev = byPlace.get(id);
    if (!prev) {
      byPlace.set(id, recomputeVotes(next));
      continue;
    }
    const voters = { ...prev.voters, ...next.voters };
    const merged = {
      ...prev,
      ...next,
      checks: Math.max(prev.checks || 1, next.checks || 1),
      voters,
      confirmed: prev.confirmed === true || next.confirmed === true,
    };
    byPlace.set(id, recomputeVotes(merged));
  }
  return Array.from(byPlace.values()).sort((a, b) => (b.likes - a.likes) || (a.name || "").localeCompare(b.name || ""));
}

function recomputeVotes(g) {
  let likes = 0;
  let dislikes = 0;
  for (const v of Object.values(g.voters || {})) {
    if (v === "like") likes++;
    else if (v === "dislike") dislikes++;
  }
  return { ...g, likes, dislikes };
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // GET /gpt/games
    if (path === "/gpt/games" && request.method === "GET") {
      const data = await loadList(env);
      return json(data);
    }

    // PUT /gpt/games  body: { games: [...] }  (merge by placeId)
    if (path === "/gpt/games" && (request.method === "PUT" || request.method === "POST")) {
      if (GPT_WRITE_TOKEN) {
        const auth = request.headers.get("Authorization") || "";
        const token = request.headers.get("X-Ivory-Token") || "";
        const okAuth = auth === ("Bearer " + GPT_WRITE_TOKEN) || token === GPT_WRITE_TOKEN;
        if (!okAuth) return json({ error: "unauthorized" }, 401);
      }
      try {
        const body = await request.json();
        const incoming = Array.isArray(body) ? body : (body && body.games) || [];
        const current = await loadList(env);
        const games = mergeGames(current.games, incoming);
        const saved = await saveList(env, { version: 1, games });
        return json(saved);
      } catch (e) {
        return json({ error: "bad body" }, 400);
      }
    }

    // POST /validate { key: "xxx", provider: "workink"|"lootlabs" }
    if (path === "/validate" && request.method === "POST") {
      try {
        const body = await request.json();
        const { key, provider } = body;

        if (!key || !provider) {
          return json({ valid: false, error: "Missing key or provider" }, 400);
        }

        if (provider === "workink") {
          const res = await fetch(`https://work.ink/_api/v2/token/isValid/${key}?deleteToken=1`);
          const data = await res.json();
          return json({ valid: data.valid, provider: "workink" });
        }

        if (provider === "lootlabs") {
          const res = await fetch(`https://creators.lootlabs.gg/api/public/validate?key=${key}`, {
            headers: { Authorization: `Bearer ${LOOTLABS_KEY}` },
          });
          const data = await res.json();
          return json({ valid: data.valid || data.success, provider: "lootlabs" });
        }

        return json({ valid: false, error: "Unknown provider" }, 400);
      } catch (e) {
        return json({ valid: false, error: "Server error" }, 500);
      }
    }

    return new Response("Ivory Hub Backend", { headers: corsHeaders });
  },
};
