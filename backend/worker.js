// Cloudflare Worker - Key Validation Proxy
// Deploy this at: your-app.workers.dev

const LOOTLABS_KEY = "YOUR_LOOTLABS_KEY_HERE";
const WORKINK_KEY = "YOUR_WORKINK_KEY_HERE";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default {
  async fetch(request) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    // POST /validate { key: "xxx", provider: "workink"|"lootlabs" }
    if (path === "/validate" && request.method === "POST") {
      try {
        const body = await request.json();
        const { key, provider } = body;

        if (!key || !provider) {
          return new Response(JSON.stringify({ valid: false, error: "Missing key or provider" }), {
            status: 400,
            headers: { "Content-Type": "application/json", ...corsHeaders },
          });
        }

        if (provider === "workink") {
          const res = await fetch(`https://work.ink/_api/v2/token/isValid/${key}?deleteToken=1`);
          const data = await res.json();
          return new Response(JSON.stringify({ valid: data.valid, provider: "workink" }), {
            headers: { "Content-Type": "application/json", ...corsHeaders },
          });
        }

        if (provider === "lootlabs") {
          const res = await fetch(`https://creators.lootlabs.gg/api/public/validate?key=${key}`, {
            headers: { Authorization: `Bearer ${LOOTLABS_KEY}` },
          });
          const data = await res.json();
          return new Response(JSON.stringify({ valid: data.valid || data.success, provider: "lootlabs" }), {
            headers: { "Content-Type": "application/json", ...corsHeaders },
          });
        }

        return new Response(JSON.stringify({ valid: false, error: "Unknown provider" }), {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      } catch (e) {
        return new Response(JSON.stringify({ valid: false, error: "Server error" }), {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }
    }

    return new Response("Ivory Hub Key Backend", { headers: corsHeaders });
  },
};
