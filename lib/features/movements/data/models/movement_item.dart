class MovementItem {
  final String tipoMovimiento;
  final DateTime fecha;
  final double monto;

  MovementItem({
    required this.tipoMovimiento,
    required this.fecha,
    required this.monto,
  });

  factory MovementItem.fromJson(Map<String, dynamic> json) {
    return MovementItem(
      tipoMovimiento: json['tipoMovimiento']?.toString() ?? json['tipo']?.toString() ?? 'Desconocido',
      fecha: json['fecha'] != null 
          ? DateTime.parse(json['fecha'].toString()) 
          : DateTime.now(),
      monto: (json['monto'] ?? 0).toDouble(),
    );
  }
}
