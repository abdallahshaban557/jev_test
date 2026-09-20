import 'package:jev_dart/jev_dart.dart';

String friendlyError(Object error) => switch (error) {
  AuthenticationException() =>
    'Jev rejected this API key. Check it and try again.',
  PermissionDeniedException() => 'This API key does not have access to Jev.',
  RateLimitException() => 'Too many requests. Wait a moment and retry.',
  NotFoundException() => 'The Jev endpoint was not found. Stop and restart Flutter to load the development proxy.',
  ApiException(status: 502) =>
    'The development proxy could not reach Jev. Please retry.',
  FormatException() => 'The server returned an unexpected response. In Chrome debug, stop and restart Flutter to load the development proxy.',
  ApiConnectionException() =>
    'Could not reach Jev. Check your connection and retry.',
  _ => 'Jev could not return a valid choice. Please try again.',
};
