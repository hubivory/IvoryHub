// Cloudflare Worker - Key Validation + GPT shared games list
// Deploy: npx wrangler deploy
// KV: npx wrangler kv namespace create GAMES  (then set id in wrangler.toml)
// Secret: npx wrangler secret put GITHUB_TOKEN  (contents:write on hubivory/IvoryHub)

const LOOTLABS_KEY = "YOUR_LOOTLABS_KEY_HERE";
const WORKINK_KEY = "YOUR_WORKINK_KEY_HERE";
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

function recomputeVotes(g) {
  let likes = 0;
  let dislikes = 0;
  for (const v of Object.values(g.voters || {})) {
    if (v === "like") likes++;
    else if (v === "dislike") dislikes++;
  }
  return { ...g, likes, dislikes };
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
  return Array.from(byPlace.values()).sort(
    (a, b) => b.likes - a.likes || (a.name || "").localeCompare(b.name || "")
  );
}

async function loadList(env) {
  if (env.GAMES) {
    const raw = await env.GAMES.get("list", { type: "json" });
    if (raw && Array.isArray(raw.games) && raw.games.length > 0) {
      return raw;
    }
  }
  // Fallback via GitHub API (not raw CDN — CDN is stale)
  try {
    const metaRes = await fetch(
      "https://api.github.com/repos/hubivory/IvoryHub/contents/library/vulnerable-games.json",
      {
        headers: {
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          "User-Agent": "ivoryhub-worker",
          ...(env.GITHUB_TOKEN ? { Authorization: `Bearer ${env.GITHUB_TOKEN}` } : {}),
        },
      }
    );
    if (metaRes.ok) {
      const meta = await metaRes.json();
      const text = decodeURIComponent(
        atob((meta.content || "").replace(/\n/g, ""))
          .split("")
          .map((c) => "%" + c.charCodeAt(0).toString(16).padStart(2, "0"))
          .join("")
      );
      const data = JSON.parse(text);
      if (data && Array.isArray(data.games) && data.games.length > 0) {
        if (env.GAMES) {
          try {
            await env.GAMES.put("list", JSON.stringify(data));
          } catch {}
        }
        return data;
      }
    }
  } catch {}
  return { version: 1, updatedAt: new Date().toISOString(), games: [] };
}

async function syncListToGitHub(env, data) {
  const token = env.GITHUB_TOKEN;
  if (!token) return { ok: false, skipped: true, error: "no GITHUB_TOKEN" };
  const owner = "hubivory";
  const repo = "IvoryHub";
  const path = "library/vulnerable-games.json";
  const api = `https://api.github.com/repos/${owner}/${repo}/contents/${path}`;
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "ivoryhub-worker",
  };

  let sha;
  const getRes = await fetch(api, { headers });
  if (getRes.ok) {
    const meta = await getRes.json();
    sha = meta.sha;
  } else if (getRes.status !== 404) {
    return { ok: false, error: "get " + getRes.status };
  }

  const body = JSON.stringify(
    { version: 1, updatedAt: data.updatedAt, games: data.games || [] },
    null,
    2
  );
  const bytes = new TextEncoder().encode(body);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  const content = btoa(binary);

  const putRes = await fetch(api, {
    method: "PUT",
    headers,
    body: JSON.stringify({
      message: `chore: sync Working Games list (${(data.games || []).length} games)`,
      content,
      ...(sha ? { sha } : {}),
    }),
  });
  if (!putRes.ok) {
    const text = await putRes.text();
    return { ok: false, error: "put " + putRes.status + " " + text.slice(0, 160) };
  }
  const putJson = await putRes.json().catch(() => ({}));
  return { ok: true, sha: putJson.content && putJson.content.sha };
}

async function saveList(env, data) {
  data.version = 1;
  data.updatedAt = new Date().toISOString();
  if (env.GAMES) {
    await env.GAMES.put("list", JSON.stringify(data));
  }
  let github = { ok: false, skipped: true, error: "disabled" };
  try {
    github = await syncListToGitHub(env, data);
  } catch (e) {
    github = { ok: false, error: String(e && e.message || e) };
  }
  data.github = github;
  return data;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    if (path === "/gpt/games" && request.method === "GET") {
      const data = await loadList(env);
      return json(data);
    }

    // Wipe the shared Working Games list (KV + GitHub).
    // Owner-only: requires RESET_KEY secret (?key= or Authorization: Bearer).
    // Disabled entirely if the secret is not set.
    const isReset =
      (path === "/gpt/games" && request.method === "DELETE") ||
      (path === "/gpt/reset" && request.method === "GET");
    if (isReset) {
      if (!env.RESET_KEY) return json({ error: "reset disabled" }, 403);
      const auth = request.headers.get("Authorization") || "";
      const urlTok = url.searchParams.get("key") || "";
      const okAuth = urlTok === env.RESET_KEY || auth === "Bearer " + env.RESET_KEY;
      if (!okAuth) return json({ error: "forbidden" }, 403);
      try {
        const saved = await saveList(env, { version: 1, games: [] });
        return json(saved);
      } catch (e) {
        return json({ error: "reset failed", detail: String(e && e.message || e) }, 400);
      }
    }

    // GET fallback for executors that break on PUT/POST bodies
    if (path === "/gpt/report" && request.method === "GET") {
      try {
        const placeId = Number(url.searchParams.get("placeId") || 0);
        if (!placeId) return json({ error: "placeId required" }, 400);
        const incoming = [
          {
            placeId,
            gameId: Number(url.searchParams.get("gameId") || 0) || 0,
            name: url.searchParams.get("name") || "Unknown",
            verdict: url.searchParams.get("verdict") || "?",
            checks: Number(url.searchParams.get("checks") || 1) || 1,
            likes: Number(url.searchParams.get("likes") || 0) || 0,
            dislikes: Number(url.searchParams.get("dislikes") || 0) || 0,
            confirmed: url.searchParams.get("confirmed") === "1" || url.searchParams.get("confirmed") === "true",
            lastCheck: url.searchParams.get("lastCheck") || new Date().toISOString(),
            reporter: url.searchParams.get("reporter") || "?",
          },
        ];
        const current = await loadList(env);
        const games = mergeGames(current.games, incoming);
        const saved = await saveList(env, { version: 1, games });
        return json(saved);
      } catch (e) {
        return json({ error: "report failed", detail: String(e && e.message || e) }, 400);
      }
    }

    if (path === "/gpt/games" && (request.method === "PUT" || request.method === "POST")) {
      if (GPT_WRITE_TOKEN) {
        const auth = request.headers.get("Authorization") || "";
        const token = request.headers.get("X-Ivory-Token") || "";
        const okAuth = auth === "Bearer " + GPT_WRITE_TOKEN || token === GPT_WRITE_TOKEN;
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

    if (path === "/validate" && request.method === "POST") {
      try {
        const body = await request.json();
        const { key, provider } = body;
        if (!key || !provider) return json({ valid: false, error: "Missing key or provider" }, 400);
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
