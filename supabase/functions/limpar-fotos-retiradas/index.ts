import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const headers = {
    apikey: supabaseKey,
    Authorization: `Bearer ${supabaseKey}`,
    "Content-Type": "application/json",
  };

  const agora = new Date().toISOString();
const res = await fetch(
  `${supabaseUrl}/rest/v1/encomendas?foto_expira_em=lt.${agora}&foto_url=not.is.null&select=id,foto_url`,
    { headers }
  );
  const encomendas = await res.json();

  if (!encomendas.length) {
    return new Response(JSON.stringify({ deletadas: 0 }), { status: 200 });
  }

  let deletadas = 0;
  for (const enc of encomendas) {
    const partes = enc.foto_url.split('/encomendas/');
    if (partes.length > 1) {
      const fileName = partes[1];
      await fetch(
        `${supabaseUrl}/storage/v1/object/encomendas/${fileName}`,
        { method: "DELETE", headers }
      );
    }
    await fetch(
      `${supabaseUrl}/rest/v1/encomendas?id=eq.${enc.id}`,
      {
        method: "PATCH",
        headers,
        body: JSON.stringify({ foto_url: null }),
      }
    );
    deletadas++;
  }

  return new Response(JSON.stringify({ deletadas }), { status: 200 });
});
