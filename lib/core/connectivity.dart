import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cihazda internet baglantisi olup olmadigini yayinlar.
///
/// connectivity_plus baglanti TURUNU (wifi/mobil/yok) bildirir, gercek
/// internet erisimini garanti etmez; ancak "baglanti hic yok" durumunu
/// guvenilir sekilde yakalar. Ilk degeri aninda, sonrasinda her
/// degisiklikte yeni deger uretir.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOnline);
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}
