import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/data/datasources/local/auth_local_datasource.dart';

void main() {
  group('AuthLocalDataSource Tests', () {
    late AuthLocalDataSourceImpl dataSource;

    setUp(() {
      dataSource = AuthLocalDataSourceImpl();
    });

    test('cacheAuthToken stores token successfully', () async {
      const testToken = 'test_auth_token_12345';
      
      await dataSource.cacheAuthToken(testToken);
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, testToken);
    });

    test('getAuthToken returns null when no token is cached', () async {
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, null);
    });

    test('clearAuthToken removes cached token', () async {
      const testToken = 'test_auth_token_12345';
      
      await dataSource.cacheAuthToken(testToken);
      await dataSource.clearAuthToken();
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, null);
    });

    test('cacheAuthToken overwrites existing token', () async {
      const firstToken = 'first_token';
      const secondToken = 'second_token';
      
      await dataSource.cacheAuthToken(firstToken);
      await dataSource.cacheAuthToken(secondToken);
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, secondToken);
      expect(retrievedToken, isNot(firstToken));
    });

    test('cacheAuthToken handles empty string', () async {
      const emptyToken = '';
      
      await dataSource.cacheAuthToken(emptyToken);
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, '');
    });

    test('cacheAuthToken handles long token', () async {
      final longToken = 'a' * 1000;
      
      await dataSource.cacheAuthToken(longToken);
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, longToken);
      expect(retrievedToken?.length, 1000);
    });

    test('cacheAuthToken handles special characters', () async {
      const specialToken = 'token.with-special_chars@123#\$%';
      
      await dataSource.cacheAuthToken(specialToken);
      final retrievedToken = await dataSource.getAuthToken();
      
      expect(retrievedToken, specialToken);
    });

    test('clearAuthToken is idempotent', () async {
      await dataSource.clearAuthToken();
      await dataSource.clearAuthToken();
      await dataSource.clearAuthToken();
      
      final retrievedToken = await dataSource.getAuthToken();
      expect(retrievedToken, null);
    });

    test('multiple cache and clear operations work correctly', () async {
      const token1 = 'token1';
      const token2 = 'token2';
      const token3 = 'token3';
      
      await dataSource.cacheAuthToken(token1);
      expect(await dataSource.getAuthToken(), token1);
      
      await dataSource.clearAuthToken();
      expect(await dataSource.getAuthToken(), null);
      
      await dataSource.cacheAuthToken(token2);
      expect(await dataSource.getAuthToken(), token2);
      
      await dataSource.cacheAuthToken(token3);
      expect(await dataSource.getAuthToken(), token3);
      
      await dataSource.clearAuthToken();
      expect(await dataSource.getAuthToken(), null);
    });

    test('getAuthToken returns the same token on multiple calls', () async {
      const testToken = 'test_token';
      
      await dataSource.cacheAuthToken(testToken);
      final retrieved1 = await dataSource.getAuthToken();
      final retrieved2 = await dataSource.getAuthToken();
      final retrieved3 = await dataSource.getAuthToken();
      
      expect(retrieved1, testToken);
      expect(retrieved2, testToken);
      expect(retrieved3, testToken);
    });
  });
}
