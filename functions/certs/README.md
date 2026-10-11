# Apple root certificates

`src/store/apple.ts` verifies every App Store JWS (API responses and App
Store Server Notifications v2) against Apple's root CAs. Put the DER
files here before deploying:

- `AppleRootCA-G3.cer` — https://www.apple.com/certificateauthority/AppleRootCA-G3.cer
- `AppleRootCA-G2.cer` — https://www.apple.com/certificateauthority/AppleRootCA-G2.cer
- `AppleIncRootCertificate.cer` — https://www.apple.com/appleca/AppleIncRootCertificate.cer

Download them yourself from apple.com (don't take copies from third
parties) and commit them — they are public certificates.
