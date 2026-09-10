import { importPKCS8, SignJWT, createRemoteJWKSet, jwtVerify } from 'npm:jose@5.10.0';

const projectId = Deno.env.get('FIREBASE_PROJECT_ID') ?? '';
const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL') ?? '';
const privateKey = (Deno.env.get('FIREBASE_PRIVATE_KEY') ?? '').replace(/\\n/g, '\n');
const firestoreBase = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
const firebaseKeys = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'),
);

export type FirebaseClaims = { sub: string; email?: string; name?: string };

export class FirebaseTokenError extends Error {
  constructor(public readonly reason: 'missing' | 'invalid') {
    super(`Firebase token ${reason}`);
  }
}

function requireFirebaseConfig() {
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error('Firebase service account secrets are not configured');
  }
}

export async function verifyFirebaseToken(token: string): Promise<FirebaseClaims> {
  if (!token) throw new FirebaseTokenError('missing');
  let result;
  try {
    result = await jwtVerify(token, firebaseKeys, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });
  } catch (_) {
    throw new FirebaseTokenError('invalid');
  }
  const sub = result.payload.sub;
  if (!sub) throw new FirebaseTokenError('invalid');
  return {
    sub,
    email: result.payload.email?.toString(),
    name: result.payload.name?.toString(),
  };
}

async function serviceAccessToken(): Promise<string> {
  requireFirebaseConfig();
  const key = await importPKCS8(privateKey, 'RS256');
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/datastore',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt()
    .setExpirationTime('1h')
    .sign(key);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error('Could not obtain Firebase access token');
  const data = await response.json();
  return data.access_token as string;
}

export async function firestoreGet(path: string): Promise<Record<string, any> | null> {
  const response = await fetch(`${firestoreBase}/${path}`, {
    headers: { Authorization: `Bearer ${await serviceAccessToken()}` },
  });
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Firestore read failed: ${response.status}`);
  const document = await response.json();
  return fromFirestoreFields(document.fields ?? {});
}

export async function firestorePatch(
  path: string,
  values: Record<string, unknown>,
): Promise<void> {
  const fields = Object.fromEntries(
    Object.entries(values).map(([key, value]) => [key, toFirestoreValue(value)]),
  );
  const updateMask = Object.keys(values)
    .map((field) => `updateMask.fieldPaths=${encodeURIComponent(field)}`)
    .join('&');
  const response = await fetch(`${firestoreBase}/${path}?${updateMask}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${await serviceAccessToken()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) throw new Error(`Firestore write failed: ${response.status}`);
}

function toFirestoreValue(value: unknown): Record<string, unknown> {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') return { integerValue: Math.trunc(value).toString() };
  return { stringValue: String(value) };
}

function fromFirestoreFields(fields: Record<string, any>): Record<string, any> {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, fromFirestoreValue(value)]),
  );
}

function fromFirestoreValue(value: Record<string, any>): unknown {
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('timestampValue' in value) return value.timestampValue;
  return null;
}
