import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_token';
const _credEmailKey = 'cred_email';
const _credPasswordKey = 'cred_password';

class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _tokenKey);
  Future<void> write(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

class SavedCredentials {
  final String email;
  final String password;
  const SavedCredentials(this.email, this.password);
}

class CredentialsStore {
  CredentialsStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<SavedCredentials?> read() async {
    final email = await _storage.read(key: _credEmailKey);
    final pass = await _storage.read(key: _credPasswordKey);
    if (email == null || email.isEmpty || pass == null || pass.isEmpty) {
      return null;
    }
    return SavedCredentials(email, pass);
  }

  Future<void> save(String email, String password) async {
    await _storage.write(key: _credEmailKey, value: email);
    await _storage.write(key: _credPasswordKey, value: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _credEmailKey);
    await _storage.delete(key: _credPasswordKey);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(const FlutterSecureStorage());
});

final credentialsStoreProvider = Provider<CredentialsStore>((ref) {
  return CredentialsStore(const FlutterSecureStorage());
});
