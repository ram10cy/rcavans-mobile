/// hrplus izin kaydı.
class IzinItem {
  final int id;
  final int tip;
  final String tipLabel;
  final bool saatlik;
  final DateTime? baslangicGunu;
  final DateTime? bitisGunu;
  final String? baslangicSaati;
  final String? bitisSaati;
  final int toplamGun;
  final int toplamSaat; // dakika cinsinden
  final String? aciklama;
  final int durum;
  final String durumLabel;
  final bool ilkAmirOnayli;
  final bool ustAmirOnayli;

  const IzinItem({
    required this.id,
    required this.tip,
    required this.tipLabel,
    required this.saatlik,
    this.baslangicGunu,
    this.bitisGunu,
    this.baslangicSaati,
    this.bitisSaati,
    required this.toplamGun,
    required this.toplamSaat,
    this.aciklama,
    required this.durum,
    required this.durumLabel,
    required this.ilkAmirOnayli,
    required this.ustAmirOnayli,
  });

  factory IzinItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return IzinItem(
      id: json['id'] as int,
      tip: json['tip'] as int? ?? 0,
      tipLabel: json['tip_label'] as String? ?? '',
      saatlik: json['saatlik'] as bool? ?? false,
      baslangicGunu: parse(json['baslangic_gunu']),
      bitisGunu: parse(json['bitis_gunu']),
      baslangicSaati: json['baslangic_saati'] as String?,
      bitisSaati: json['bitis_saati'] as String?,
      toplamGun: json['toplam_gun'] as int? ?? 0,
      toplamSaat: json['toplam_saat'] as int? ?? 0,
      aciklama: json['aciklama'] as String?,
      durum: json['durum'] as int? ?? 0,
      durumLabel: json['durum_label'] as String? ?? '',
      ilkAmirOnayli: json['ilk_amir_onayli'] as bool? ?? false,
      ustAmirOnayli: json['ust_amir_onayli'] as bool? ?? false,
    );
  }

  /// Saatlik izinde toplam süreyi "2sa 30dk" biçiminde verir.
  String get sureMetni {
    if (saatlik) {
      final s = toplamSaat ~/ 60;
      final d = toplamSaat % 60;
      return '${s}sa ${d}dk';
    }
    return '$toplamGun gün';
  }
}

/// İzin listesi + kalan yıllık izin hakkı.
class IzinlerData {
  final double kalanHak;
  final List<IzinItem> izinler;

  const IzinlerData({required this.kalanHak, required this.izinler});
}

/// Talep edilebilir izin türü.
class IzinTuru {
  final int tip;
  final String ad;
  final bool saatlik;

  const IzinTuru({required this.tip, required this.ad, required this.saatlik});

  factory IzinTuru.fromJson(Map<String, dynamic> json) => IzinTuru(
        tip: json['tip'] as int,
        ad: json['ad'] as String,
        saatlik: json['saatlik'] as bool? ?? false,
      );
}

/// Açıklamanın zorunlu olduğu izin türleri (idari izinler).
const kAciklamaZorunluTipler = <int>[7, 10];
