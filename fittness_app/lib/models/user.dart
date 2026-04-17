class User {
  final int id;
  final String nome;
  final String email;
  final int eta;
  final String sesso;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.eta,
    required this.sesso,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num).toInt(),
        nome: j['nome']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        eta: (j['eta'] as num?)?.toInt() ?? 0,
        sesso: j['sesso']?.toString() ?? 'Altro',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'eta': eta,
        'sesso': sesso,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}
