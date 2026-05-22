/// hrplus çağrı kaydı (IT/destek talebi).
class CagriItem {
  final int id;
  final String baslik;
  final String icerik;
  final String aciliyet;
  final int durum;
  final String durumLabel;
  final String? kapatmaAciklama;
  final DateTime? acilmaTarihi;
  final DateTime? kapanmaTarihi;

  const CagriItem({
    required this.id,
    required this.baslik,
    required this.icerik,
    required this.aciliyet,
    required this.durum,
    required this.durumLabel,
    this.kapatmaAciklama,
    this.acilmaTarihi,
    this.kapanmaTarihi,
  });

  factory CagriItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return CagriItem(
      id: json['id'] as int,
      baslik: json['baslik'] as String? ?? '',
      icerik: json['icerik'] as String? ?? '',
      aciliyet: json['aciliyet'] as String? ?? '',
      durum: json['durum'] as int? ?? 0,
      durumLabel: json['durum_label'] as String? ?? '',
      kapatmaAciklama: json['kapatma_aciklama'] as String?,
      acilmaTarihi: parse(json['acilma_tarihi']),
      kapanmaTarihi: parse(json['kapanma_tarihi']),
    );
  }
}

/// hrplus'ın kabul ettiği aciliyet değerleri.
const kCagriAciliyetleri = <String>[
  'Acil/ Kritik',
  'Orta Seviye',
  'Düşük Öncelik',
];
