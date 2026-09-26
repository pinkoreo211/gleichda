// Sends whatever is waiting in the notification outbox.
//
// Runs on Supabase with the service role, which is the only place a key
// like that may live. Nothing in the app can call this and nothing in the
// app can choose who gets a push: this reads the outbox, and the outbox is
// written only by the database functions that performed the step.
//
// It drains the queue rather than trusting its input, so the same function
// works whether it was woken by a database webhook on a new row or by a
// schedule catching up after an outage. A webhook body is ignored on
// purpose -- acting on it would mean acting on something the caller said.
//
// Failure is expected and handled: a note that could not be delivered is
// counted and retried twice, then left alone. A device the push service
// rejects is deleted, because a token that is gone stays gone.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const MAX_BATCH = 20;

type Note = {
  id: string;
  recipient_id: string;
  kind: string;
  contact_id: string | null;
  payload: Record<string, unknown>;
  attempts: number;
  tokens: string[];
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};

/// The wording, in one place, so changing it needs no migration.
///
/// German only for now: the launch market is Vienna, and nothing records
/// which language a person reads the app in. When that exists, this
/// switches on it — the shape below does not have to change.
function textFor(note: Note): { title: string; body: string } {
  const name = (note.payload.customer_name as string | null) ?? null;
  const other = (note.payload.other_name as string | null) ?? null;
  const service = (note.payload.service_name as string | null) ?? null;

  switch (note.kind) {
    case 'booking_received':
      return {
        title: 'Neue Anfrage',
        body: name && service
          ? `${name} hat dich für ${service} angefragt.`
          : service
          ? `Du hast eine neue Anfrage für ${service}.`
          : 'Du hast eine neue Anfrage.',
      };
    case 'request_accepted':
      return {
        title: 'Anfrage angenommen',
        body: other
          ? `${other} hat deine Anfrage angenommen.`
          : 'Deine Anfrage wurde angenommen.',
      };
    case 'appointment_agreed':
      return { title: 'Termin steht', body: 'Ihr habt einen Termin vereinbart.' };
    case 'provider_on_the_way':
      return {
        title: 'Unterwegs',
        body: other ? `${other} ist unterwegs zu dir.` : 'Dein Dienstleister ist unterwegs.',
      };
    case 'job_completed':
      return {
        title: 'Auftrag fertig',
        body: 'Der Auftrag wurde als fertig gemeldet. Bitte bestätige ihn.',
      };
    case 'job_confirmed':
      return { title: 'Auftrag bestätigt', body: 'Der Kunde hat den Auftrag bestätigt.' };
    case 'chat_message':
      // Deliberately without the message itself: a push shows up on a lock
      // screen, and what two people write each other does not belong there.
      return {
        title: 'Neue Nachricht',
        body: other ? `${other} hat dir geschrieben.` : 'Du hast eine neue Nachricht.',
      };
    default:
      return { title: 'GleichDa', body: 'Es gibt etwas Neues.' };
  }
}

/// Mints a short-lived access token from the service account, the way
/// Google's own libraries do. Done by hand because pulling a full SDK into
/// an edge function for one signed JWT is not worth it.
async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: account.client_email,
    scope: FCM_SCOPE,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encode = (value: unknown) =>
    btoa(JSON.stringify(value)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const unsigned = `${encode(header)}.${encode(claims)}`;

  const pem = account.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const signed = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${signed}`,
    }),
  });

  if (!response.ok) {
    throw new Error(`Google refused the service account: ${await response.text()}`);
  }
  const body = await response.json();
  return body.access_token as string;
}

/// One device. Returns null on success, or a reason, plus whether the
/// token should be thrown away.
async function sendToDevice(
  token: string,
  note: Note,
  projectId: string,
  bearer: string,
): Promise<{ error: string | null; tokenIsDead: boolean }> {
  const { title, body } = textFor(note);

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${bearer}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          // What the app needs to open the right thing. Strings only:
          // FCM data values are not allowed to be anything else.
          data: {
            kind: note.kind,
            contact_id: note.contact_id ?? '',
          },
          android: { priority: 'high' },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        },
      }),
    },
  );

  if (response.ok) return { error: null, tokenIsDead: false };

  const text = await response.text();
  // 404 UNREGISTERED and 400 with an invalid registration token both mean
  // this device will never be reachable again.
  const dead =
    response.status === 404 ||
    text.includes('UNREGISTERED') ||
    text.includes('INVALID_ARGUMENT');
  return { error: `${response.status} ${text}`.slice(0, 500), tokenIsDead: dead };
}

Deno.serve(async () => {
  const url = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const rawAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

  if (!url || !serviceKey) {
    return new Response('Supabase environment missing', { status: 500 });
  }
  if (!rawAccount) {
    return new Response('FIREBASE_SERVICE_ACCOUNT is not set', { status: 500 });
  }

  const supabase = createClient(url, serviceKey);

  const { data: notes, error } = await supabase.rpc('pending_notifications', {
    batch_size: MAX_BATCH,
  });
  if (error) return new Response(error.message, { status: 500 });

  const pending = (notes ?? []) as Note[];
  if (pending.length === 0) {
    return Response.json({ sent: 0, failed: 0, skipped: 0 });
  }

  const account = JSON.parse(rawAccount) as ServiceAccount;
  const bearer = await accessToken(account);

  let sent = 0;
  let failed = 0;
  let skipped = 0;

  for (const note of pending) {
    // Nobody to tell. Counted as done rather than retried: the person has
    // no device registered, and trying again will not give them one.
    if (!note.tokens || note.tokens.length === 0) {
      await supabase.rpc('mark_notification_sent', { note_id: note.id });
      skipped++;
      continue;
    }

    const failures: string[] = [];
    let delivered = 0;

    for (const token of note.tokens) {
      try {
        const result = await sendToDevice(token, note, account.project_id, bearer);
        if (result.error === null) {
          delivered++;
        } else {
          failures.push(result.error);
          if (result.tokenIsDead) {
            await supabase.rpc('drop_push_token', { device_token: token });
          }
        }
      } catch (problem) {
        failures.push(String(problem).slice(0, 500));
      }
    }

    // One device reached is enough: the person has been told.
    if (delivered > 0) {
      await supabase.rpc('mark_notification_sent', { note_id: note.id });
      sent++;
    } else {
      await supabase.rpc('mark_notification_failed', {
        note_id: note.id,
        reason: failures.join(' | '),
      });
      failed++;
    }
  }

  return Response.json({ sent, failed, skipped });
});
