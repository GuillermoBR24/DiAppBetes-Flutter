// worker.js — Despliega esto en Cloudflare Workers (gratis, sin tarjeta)
// Wrangler: npx wrangler deploy
//
// Secrets necesarios (npx wrangler secret put NOMBRE):
//   FIREBASE_PROJECT_ID     -> tu-proyecto
//   FIREBASE_CLIENT_EMAIL   -> del JSON de tu Service Account
//   FIREBASE_PRIVATE_KEY    -> del JSON de tu Service Account (con \n literales)
//   RESEND_API_KEY          -> de resend.com (o cambia sendEmail() por Brevo)
//
// El Service Account: Firebase Console → Configuración del proyecto →
// Cuentas de servicio → Generar nueva clave privada.

// ── 1. Firmar un JWT con la clave del Service Account (Web Crypto, sin Node) ──
async function getGoogleAccessToken(env) {
  const header = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: env.FIREBASE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/identitytoolkit',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const enc = (obj) =>
    btoa(JSON.stringify(obj)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

  const unsigned = `${enc(header)}.${enc(claim)}`;

  const pemKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binaryKey = Uint8Array.from(atob(pemKey), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsigned)
  );

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

  const jwt = `${unsigned}.${sigB64}`;

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) throw new Error('No se pudo obtener el access token');
  return tokenData.access_token;
}

// ── 2. Pedir a Identity Toolkit el link (sin que Firebase mande su email) ──
async function generateOobLink(env, accessToken, email, requestType) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/accounts:sendOobCode`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        requestType, // 'VERIFY_EMAIL' o 'PASSWORD_RESET'
        email,
        returnOobLink: true,
      }),
    }
  );
  const data = await res.json();
  if (!data.oobLink) throw new Error(JSON.stringify(data));
  return data.oobLink;
}

// ── 3. Enviar el email con tu HTML propio vía Brevo (sin dominio propio) ──
async function sendEmail(env, to, subject, html) {
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': env.BREVO_API_KEY,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      sender: { name: 'DiAppBetes', email: 'tuapp@gmail.com' }, // el email que verificaste en Brevo
      to: [{ email: to }],
      subject,
      htmlContent: html,
    }),
  });
  if (!res.ok) throw new Error(await res.text());
}

function verificationHtml(link) {
  return `
    <div style="font-family:sans-serif;max-width:480px;margin:auto">
      <h2>¡Bienvenido/a a DiAppBetes!</h2>
      <p>Confirma tu correo haciendo clic en el siguiente botón:</p>
      <a href="${link}" style="background:#2E7D32;color:#fff;padding:12px 20px;
         border-radius:8px;text-decoration:none;display:inline-block">
         Verificar mi cuenta
      </a>
      <p style="color:#888;font-size:12px">Si no creaste esta cuenta, ignora este correo.</p>
    </div>`;
}

function resetHtml(link) {
  return `
    <div style="font-family:sans-serif;max-width:480px;margin:auto">
      <h2>Recuperar contraseña</h2>
      <p>Haz clic en el botón para crear una nueva contraseña:</p>
      <a href="${link}" style="background:#1565C0;color:#fff;padding:12px 20px;
         border-radius:8px;text-decoration:none;display:inline-block">
         Restablecer contraseña
      </a>
      <p style="color:#888;font-size:12px">Si no lo solicitaste, ignora este correo.</p>
    </div>`;
}

// ── 4. Endpoint HTTPS que llamará tu app Flutter ─────────────────────────

// Cabeceras CORS. En producción, cambia '*' por tu dominio real
// (ej. 'https://tuapp.web.app') para que solo tu app pueda llamar al Worker.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, env) {
    // El navegador manda esto antes del POST real ("preflight") — hay que
    // responderlo con las cabeceras CORS o el navegador bloquea la petición.
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: corsHeaders });
    }

    try {
      const { type, email } = await request.json();
      if (!email || !['verify', 'reset'].includes(type)) {
        return new Response('Parámetros inválidos', { status: 400, headers: corsHeaders });
      }

      const accessToken = await getGoogleAccessToken(env);
      const requestType = type === 'verify' ? 'VERIFY_EMAIL' : 'PASSWORD_RESET';
      const link = await generateOobLink(env, accessToken, email, requestType);

      if (type === 'verify') {
        await sendEmail(env, email, 'Verifica tu cuenta en DiAppBetes', verificationHtml(link));
      } else {
        await sendEmail(env, email, 'Recupera tu contraseña - DiAppBetes', resetHtml(link));
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};