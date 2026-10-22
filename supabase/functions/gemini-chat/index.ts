import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "server_not_configured" }, 503);
  }
  if (!geminiApiKey) {
    return jsonResponse({ error: "ai_not_configured" }, 503);
  }

  let input: Record<string, unknown>;
  try {
    input = await request.json();
  } catch {
    return jsonResponse({ error: "invalid_request" }, 400);
  }

  const message = typeof input.message === "string" ? input.message.trim() : "";
  const systemInstruction = typeof input.systemInstruction === "string"
    ? input.systemInstruction
    : "";
  const rawHistory = Array.isArray(input.history) ? input.history : [];
  if (!message || message.length > 4000 || systemInstruction.length > 30000) {
    return jsonResponse({ error: "invalid_request" }, 400);
  }

  const history = rawHistory.slice(-12).flatMap((entry) => {
    if (typeof entry !== "object" || entry === null) return [];
    const role = Reflect.get(entry, "role");
    const text = Reflect.get(entry, "text");
    if (
      (role !== "user" && role !== "model") ||
      typeof text !== "string" ||
      text.length > 4000
    ) {
      return [];
    }
    return [{ role, parts: [{ text }] }];
  });

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const clientIp = request.headers.get("cf-connecting-ip") ??
    request.headers.get("x-real-ip") ??
    request.headers.get("x-forwarded-for")?.split(",")[0].trim() ??
    "unknown";
  const ipDigest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(clientIp),
  );
  const ipHash = Array.from(new Uint8Array(ipDigest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  const { data: ipAllowed, error: ipLimitError } = await adminClient.rpc(
    "consume_ai_request",
    {
      p_bucket_key: `ip:v2:${ipHash}`,
      p_limit: 20,
      p_window_seconds: 3600,
    },
  );
  if (ipLimitError) {
    return jsonResponse({ error: "rate_limit_unavailable" }, 503);
  }
  if (ipAllowed !== true) {
    return jsonResponse({ error: "rate_limit_exceeded" }, 429);
  }

  const { data: globalAllowed, error: globalLimitError } = await adminClient.rpc(
    "consume_ai_request",
    {
      p_bucket_key: "global:daily",
      p_limit: 500,
      p_window_seconds: 86400,
    },
  );
  if (globalLimitError) {
    return jsonResponse({ error: "rate_limit_unavailable" }, 503);
  }
  if (globalAllowed !== true) {
    return jsonResponse({ error: "daily_limit_exceeded" }, 429);
  }

  const model = "gemini-3.8-flash";
  let geminiResponse: Response;
  for (let attempt = 0; ; attempt++) {
    try {
      geminiResponse = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": geminiApiKey,
          },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: systemInstruction }] },
            contents: [...history, { role: "user", parts: [{ text: message }] }],
            generationConfig: { temperature: 0.7, maxOutputTokens: 1000 },
          }),
          signal: AbortSignal.timeout(30000),
        },
      );
    } catch {
      if (attempt < 2) {
        await new Promise((resolve) => setTimeout(resolve, 500 * (attempt + 1)));
        continue;
      }
      return jsonResponse({ error: "upstream_unavailable" }, 502);
    }

    const isTransientError = [500, 502, 503, 504].includes(
      geminiResponse.status,
    );
    if (geminiResponse.ok || !isTransientError || attempt === 2) break;

    await geminiResponse.body?.cancel();
    await new Promise((resolve) => setTimeout(resolve, 500 * (attempt + 1)));
  }

  if (!geminiResponse.ok) {
    const upstreamError = await geminiResponse.json().catch(() => null);
    const upstreamMessage = typeof upstreamError?.error?.message === "string"
      ? upstreamError.error.message.replaceAll(geminiApiKey, "[redacted]").slice(0, 300)
      : "";
    if (geminiResponse.status === 429) {
      return jsonResponse({ error: "quota_exceeded" }, 429);
    }
    if (geminiResponse.status === 503) {
      return jsonResponse({ error: "upstream_busy" }, 503);
    }
    if (geminiResponse.status === 401 || geminiResponse.status === 403) {
      return jsonResponse({ error: "upstream_key_invalid" }, 502);
    }
    if (geminiResponse.status === 404) {
      return jsonResponse({
        error: "model_unavailable",
        details: upstreamMessage,
      }, 502);
    }
    if (geminiResponse.status === 400) {
      return jsonResponse({
        error: "upstream_request_invalid",
        details: upstreamMessage,
      }, 502);
    }
    return jsonResponse({
      error: "upstream_error",
    }, 502);
  }

  const result = await geminiResponse.json();
  const text = result?.candidates?.[0]?.content?.parts
    ?.map((part: { text?: string }) => part.text ?? "")
    .join("")
    .trim();
  if (!text) {
    return jsonResponse({ error: "empty_response" }, 502);
  }
  return jsonResponse({ text });
});
