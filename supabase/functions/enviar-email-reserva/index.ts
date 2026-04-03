const RESEND_KEY = Deno.env.get("RESEND_API_KEY")!;
const ADMIN_EMAIL = "admar3000b@gmail.com";
const FROM = "noreply@sahjo.com.br";
const FROM_NAME = "AR3000 — Cabral Corporate & Offices";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "*" } });
  }

  try {
    const { email, sala_numero, sala_empresa, responsavel, data, hora_inicio, hora_fim, espacos, valor_total, observacoes } = await req.json();

    const dataFmt = new Date(data + "T12:00:00").toLocaleDateString("pt-BR", { weekday: "long", day: "numeric", month: "long", year: "numeric" });
    const cancelamentoDate = new Date(data + "T" + hora_inicio);
    cancelamentoDate.setHours(cancelamentoDate.getHours() - 48);
    const cancelamentoFmt = cancelamentoDate.toLocaleString("pt-BR");

    const html = `
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f0f2f5;font-family:'Segoe UI',sans-serif">
  <div style="max-width:560px;margin:32px auto;background:white;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08)">
    <div style="background:#1a237e;padding:28px 32px;text-align:center">
      <div style="color:white;font-size:22px;font-weight:700;letter-spacing:2px">AR3000</div>
      <div style="color:rgba(255,255,255,0.7);font-size:13px;margin-top:4px">Cabral Corporate &amp; Offices</div>
    </div>
    <div style="padding:32px">
      <div style="background:#e8f5e9;border-left:4px solid #2e7d32;border-radius:8px;padding:14px 18px;margin-bottom:24px">
        <div style="color:#2e7d32;font-weight:700;font-size:15px">✅ Reserva Confirmada!</div>
        <div style="color:#555;font-size:13px;margin-top:4px">Sua reserva foi registrada com sucesso.</div>
      </div>

      <table style="width:100%;border-collapse:collapse">
        <tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px;width:40%">Sala</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:13px">Sala ${sala_numero}${sala_empresa ? " — " + sala_empresa : ""}</td></tr>
        <tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px">Espaco(s)</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:13px">${espacos}</td></tr>
        <tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px">Data</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:13px">${dataFmt}</td></tr>
        <tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px">Horario</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:13px">${hora_inicio.substring(0,5)} — ${hora_fim.substring(0,5)}</td></tr>
        <tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px">Responsavel</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:600;font-size:13px">${responsavel}</td></tr>
        ${valor_total > 0 ? `<tr><td style="padding:10px 0;border-bottom:1px solid #f0f0f0;color:#999;font-size:13px">Valor</td>
            <td style="padding:10px 0;border-bottom:1px solid #f0f0f0;font-weight:700;font-size:15px;color:#1a237e">R$ ${parseFloat(valor_total).toFixed(2)}</td></tr>` : ""}
        ${observacoes ? `<tr><td style="padding:10px 0;color:#999;font-size:13px">Observacoes</td>
            <td style="padding:10px 0;font-size:13px">${observacoes}</td></tr>` : ""}
      </table>

      <div style="background:#fff3e0;border-left:4px solid #f57c00;border-radius:8px;padding:14px 18px;margin-top:24px">
        <div style="color:#e65100;font-weight:600;font-size:13px">⏰ Cancelamento</div>
        <div style="color:#555;font-size:13px;margin-top:4px">O cancelamento pode ser feito gratuitamente ate <strong>${cancelamentoFmt}</strong> (48h antes da reserva). Apos esse prazo, o cancelamento nao sera possivel.</div>
      </div>

      <div style="text-align:center;margin-top:28px;padding-top:20px;border-top:1px solid #f0f0f0">
        <div style="color:#999;font-size:12px">AR3000 — Cabral Corporate &amp; Offices</div>
        <div style="color:#bbb;font-size:11px;margin-top:4px">Este e um email automatico, nao responda diretamente.</div>
      </div>
    </div>
  </div>
</body>
</html>`;

    const destinatarios = [{ email: ADMIN_EMAIL }];
    if (email) destinatarios.push({ email });

    for (const dest of destinatarios) {
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { "Authorization": `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          from: `${FROM_NAME} <${FROM}>`,
          to: [dest.email],
          subject: `✅ Reserva Confirmada — Sala ${sala_numero} — ${dataFmt}`,
          html,
        }),
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
    });
  }
});
