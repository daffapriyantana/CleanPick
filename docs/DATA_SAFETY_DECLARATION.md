# Google Play Data Safety Declaration

This is a preparation checklist for the Google Play Console. Confirm each
answer in the console against the production build and the final privacy
policy before submitting.

## Data collected

| Data category | Data type | Collected | Shared | Purpose |
| --- | --- | --- | --- | --- |
| Personal | Name | Yes | With authorized officers for pickup fulfillment | App functionality |
| Personal | Email address | Yes | Firebase Authentication/provider infrastructure | Account management |
| Personal | Phone number | Yes | With authorized officers when needed for pickup | App functionality |
| Location | Approximate/precise pickup location | Optional | With assigned officer | App functionality |
| Photos and videos | Order photo | Optional | With assigned officer | App functionality |
| App activity | Order and payment status | Yes | With Firebase/Midtrans providers | App functionality |
| Device or other identifiers | FCM device token | Yes | Firebase Cloud Messaging | Notifications |

## Payment information

Payment credentials are entered and processed through Midtrans checkout. The
application stores order/payment status and provider transaction identifiers,
not the user's card, bank, or wallet credentials.

## Security declarations to verify

- Data is encrypted in transit: verify provider configuration before selecting.
- Users can request deletion: publish the official support contact and deletion
  process before selecting this answer.
- Data is not sold: select only if this remains true for the production
  service.
- Data sharing: declare Firebase and Midtrans as service providers where the
  Play Console questionnaire requires it.

## Before submission

- [ ] Replace the support contact in `PRIVACY_POLICY.md`.
- [ ] Publish the privacy policy at a public HTTPS URL.
- [ ] Verify the final release build's permissions and SDK behavior.
- [ ] Confirm optional location and photo collection behavior.
- [ ] Complete the Play Console questionnaire using the final answers.
