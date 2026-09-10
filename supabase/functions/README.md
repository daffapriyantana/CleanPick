# CleanPick Midtrans Sandbox functions

Required Supabase secrets:

- `MIDTRANS_SERVER_KEY`: Midtrans Sandbox Server Key. Set it only with `supabase secrets set`; never commit it.
- `FIREBASE_PROJECT_ID`: `clean-8376`
- `FIREBASE_CLIENT_EMAIL`: Firebase service-account client email.
- `FIREBASE_PRIVATE_KEY`: Firebase service-account private key, passed as a secret with escaped newlines.

Deploy with JWT verification disabled because these functions validate Firebase ID tokens and Midtrans signatures themselves:

```powershell
supabase functions deploy create-midtrans-transaction --no-verify-jwt
supabase functions deploy midtrans-webhook --no-verify-jwt
supabase secrets set MIDTRANS_SERVER_KEY=... FIREBASE_PROJECT_ID=... FIREBASE_CLIENT_EMAIL=... FIREBASE_PRIVATE_KEY=...
```

Configure the Midtrans Sandbox payment notification URL to:
`https://<project-ref>.supabase.co/functions/v1/midtrans-webhook`

The Flutter app receives the create endpoint URL through:
`--dart-define=SUPABASE_CREATE_PAYMENT_URL=https://<project-ref>.supabase.co/functions/v1/create-midtrans-transaction`
