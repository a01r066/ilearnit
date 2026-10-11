/**
 * App Check gate for callables. Flip enforcement per project without a
 * redeploy:  functions/.env.<alias>  →  ENFORCE_APP_CHECK=true
 * Start in monitor mode; enable when Console metrics show ~all verified.
 */
import {defineBoolean} from 'firebase-functions/params';
import {CallableRequest, HttpsError} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';

export const ENFORCE_APP_CHECK = defineBoolean('ENFORCE_APP_CHECK', {default: false});

export function requireAppCheck(request: CallableRequest<unknown>, fn: string): void {
  if (request.app) return;
  if (ENFORCE_APP_CHECK.value()) {
    throw new HttpsError('failed-precondition', 'This app could not be verified. Please update to the latest version.');
  }
  logger.debug(`${fn}: request without App Check token (monitor mode)`);
}
