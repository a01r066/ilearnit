Put Apple's root certificates here (DER, `.cer`):

- AppleRootCA-G3.cer
- AppleRootCA-G2.cer

Download from https://www.apple.com/certificateauthority/ . `store/apple.ts`
loads every `.cer`/`.der` in this folder for `SignedDataVerifier`. They
are public certificates — safe to commit. Make sure the folder is deployed
(it sits next to `lib/`, which `__dirname/../../certs` resolves to).
