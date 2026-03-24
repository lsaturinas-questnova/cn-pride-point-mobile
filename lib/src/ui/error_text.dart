import 'dart:io';

String friendlyErrorText(Object error) {
  if (error is SocketException) return 'No connection';
  if (error is HandshakeException) return 'No connection';
  return error.toString();
}

