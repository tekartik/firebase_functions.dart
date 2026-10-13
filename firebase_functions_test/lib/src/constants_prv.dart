/// Throws an HttpsError with the code given as data (not exported).
const testCommandHttpsError = 'httpserror';

/// Every callable error code but ok.
const testHttpsErrorCodes = [
  'cancelled',
  'unknown',
  'invalid-argument',
  'deadline-exceeded',
  'not-found',
  'already-exists',
  'permission-denied',
  'resource-exhausted',
  'failed-precondition',
  'aborted',
  'out-of-range',
  'unimplemented',
  'internal',
  'unavailable',
  'data-loss',
  'unauthenticated',
];
