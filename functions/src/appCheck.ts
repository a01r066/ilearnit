/**
 * App Check gate for client-facing callables.
 *
 * The callable SDK verifies an App Check token when the client sends one
 * and exposes it as `request.app`. We don't use the static
 * `enforceAppCheck: true` option so enforcement can be flipped per
 * project without code changes:
 *
 *   functions/.env.<alias>:  ENFORCE_APP_CHECK=true
 *
 * Roll out in monitor mode first (false): watch App Check metrics in the
 * Firebase Console until ~all requests carry valid tokens, then enable.
 */

import {defineBoolean} from 'firebase-functions/params';
import {CallableRequest, HttpsError} from 'firebase-functions/v2/https';
import {logger} from 'firebase-functions/v2';

export const ENFORCE_APP_CHECK = defineBoolean('ENFORCE_APP_CHECK', {default: false});

export function requireAppCheck(request: CallableRequest<unknown>, fn: string): void {
  if (request.app) return;
  if (ENFORCE_APP_CHECK.value()) {
    throw new HttpsError(
      'failed-precondition',
      'This app could not be verified. Please update to the latest version.',
    );
  }
  logger.debug(`${fn}: request without a valid App Check token (monitor mode)`);
}
