class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: true, // Should each log print contain a timestamp
    ),
  );

  // Debug level logging
  static void debug(dynamic message, {String? tag, StackTrace? stackTrace}) {
    _logger.d(message, stackTrace: stackTrace);
  }

  // Info level logging (equivalent to your old log method)
  static void log(String message, {String? tag}) {
    info(message, tag: tag);
  }

  static void info(String message, {String? tag}) {
    _logger.i(_formatMessage(message, tag));
  }

  // Warning level logging
  static void warning(String message, {String? tag}) {
    _logger.w(_formatMessage(message, tag));
  }

  // Error level logging
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _logger.e(
      _formatMessage(message, tag),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Fatal level logging
  static void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _logger.f(
      _formatMessage(message, tag),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Verbose level logging
  static void verbose(String message, {String? tag}) {
    _logger.t(_formatMessage(message, tag));
  }

  // Private helper method to format messages with tags
  static String _formatMessage(String message, String? tag) {
    if (tag != null) {
      return '[$tag] $message';
    }
    return message;
  }

  // Method to log HTTP requests/responses
  static void logApiCall({
    required String method,
    required String url,
    Map<String, dynamic>? requestData,
    int? statusCode,
    dynamic responseData,
    String? error,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🌐 API Call: $method $url');

    if (requestData != null) {
      buffer.writeln('📤 Request: $requestData');
    }

    if (statusCode != null) {
      buffer.writeln('📊 Status: $statusCode');
    }

    if (responseData != null) {
      buffer.writeln('📥 Response: $responseData');
    }

    if (error != null) {
      AppLogger.error(buffer.toString(), error: error, tag: 'API');
    } else {
      AppLogger.info(buffer.toString(), tag: 'API');
    }
  }

  // Method to log authentication events
  static void logAuth(String event, {String? userId, String? error}) {
    final message = error != null
        ? '🔐 Auth Error - $event: $error'
        : '🔐 Auth Success - $event${userId != null ? ' (User: $userId)' : ''}';

    if (error != null) {
      AppLogger.error(message, tag: 'AUTH');
    } else {
      AppLogger.info(message, tag: 'AUTH');
    }
  }

  // Method to log navigation events
  static void logNavigation(String route, {String? previous}) {
    final message = previous != null
        ? '🧭 Navigation: $previous → $route'
        : '🧭 Navigation: → $route';
    AppLogger.debug(message, tag: 'NAV');
  }
}

// For production builds, you might want a simpler logger
class AppLoggerProduction {
  static final Logger _logger = Logger(
    printer: SimplePrinter(colors: false, printTime: true),
    level: Level.info, // Only show info and above in production
  );

  static void log(String message, {String? tag}) {
    _logger.i(_formatMessage(message, tag));
  }

  static void error(String message, {dynamic error, String? tag}) {
    _logger.e(_formatMessage(message, tag), error: error);
  }

  static String _formatMessage(String message, String? tag) {
    if (tag != null) {
      return '[$tag] $message';
    }
    return message;
  }
}
