import 'dart:async';
import 'dart:io';
import '../utils/app_log.dart';

/// Standard application exception hierarchy
class AppException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

class AuthException extends AppException {
  AuthException({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// Abstract Base Repository providing safe execution, automated logging,
/// and consistent error mapping across data sources.
abstract class BaseRepository {
  final String _tag;

  BaseRepository({String? tag}) : _tag = tag ?? 'BaseRepository';

  /// Executes an asynchronous data operation safely with debug logging
  /// and mapped application exceptions.
  Future<T> safeCall<T>(
    Future<T> Function() call, {
    String? operation,
    String? customErrorMessage,
  }) async {
    final op = operation ?? 'execute';
    AppLog.d(_tag, 'Starting operation: $op');

    try {
      final result = await call();
      AppLog.d(_tag, 'Operation completed successfully: $op');
      return result;
    } on SocketException catch (e, stack) {
      AppLog.w(_tag, 'Network socket unavailable in $op: $e');
      throw NetworkException(
        message: 'No active network connection. Offline storage will handle changes.',
        originalError: e,
        stackTrace: stack,
      );
    } on TimeoutException catch (e, stack) {
      AppLog.w(_tag, 'Connection timed out during $op: $e');
      throw NetworkException(
        message: 'Server connection timed out.',
        originalError: e,
        stackTrace: stack,
      );
    } catch (e, stack) {
      AppLog.e(_tag, 'Error executing $op: $e', e, stack);
      if (e is AppException) rethrow;
      throw AppException(
        message: customErrorMessage ?? e.toString().replaceAll('Exception: ', ''),
        originalError: e,
        stackTrace: stack,
      );
    }
  }
}
