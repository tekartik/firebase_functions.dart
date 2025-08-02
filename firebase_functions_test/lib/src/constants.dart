const functionCallName = 'tktcallprvv1';
const functionCallAppCheckName = 'tktcallappcheckv1';
const callableFunctionTestName = 'tktestcallprvv1';
const httpFunctionTestName = 'tktesthttpv1';

/// For httpFunctionTestName and callableFunctionTestName
/// For functionTestCallName, part of 'command'

/// Throws an argument error
const testCommandThrow = 'throw';

/// Throws an a not found error
const testCommandNotFound = 'notfound';

/// Returns the current user id (in the call request context), null if none
const testCommandUserId = 'uid';

/// Returns incoming data as full response
const testCommandRaw = 'raw';

/// Returns input data
const testCommandData = 'data';
