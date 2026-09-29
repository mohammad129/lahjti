import 'package:flutter_test/flutter_test.dart';
import 'package:lahjti/core/errors/exceptions.dart';
import 'package:lahjti/core/errors/failures.dart';

void main() {
  group('Error Model & Network Exception Mapping', () {
    test(
      'Translates NoInternet NetworkException to friendly Arabic Failure',
      () {
        const exception = NetworkException(
          message: 'No route to host',
          errorType: NetworkErrorType.noInternet,
        );

        final failure = ErrorMapper.mapExceptionToFailure(exception);

        expect(failure, isA<NetworkFailure>());
        expect(
          failure.message,
          'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
        );
        // Ensures raw stack or exception is not exposed
        expect(failure.message.contains('No route to host'), isFalse);
      },
    );

    test('Translates ServerException to friendly generic message', () {
      const exception = ServerException(
        message: 'Internal SQL syntax error near SELECT * FROM users',
        statusCode: 500,
      );

      final failure = ErrorMapper.mapExceptionToFailure(exception);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'صار معنا خلل بسيط. جرب مرة ثانية.');
      expect(failure.message.contains('SQL'), isFalse);
    });
  });
}
