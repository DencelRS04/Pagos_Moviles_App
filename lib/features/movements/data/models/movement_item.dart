class MovementItem {
  final String tipoMovimiento;
  final double monto;
  final DateTime fecha;

  MovementItem({
    required this.tipoMovimiento,
    required this.monto,
    required this.fecha,
  });

  factory MovementItem.fromJson(Map<String, dynamic> json) {
    return MovementItem(
      tipoMovimiento: json['tipoMovimiento'] ?? '',
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha']),
    );
  }
}