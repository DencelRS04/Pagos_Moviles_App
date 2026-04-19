class AccountItem {
  final int cuentaID;
  final int clienteId;
  final String numeroCuenta;
  final double saldo;

  AccountItem({
    required this.cuentaID,
    required this.clienteId,
    required this.numeroCuenta,
    required this.saldo,
  });

  factory AccountItem.fromJson(Map<String, dynamic> json) => AccountItem(
        cuentaID: json['cuentaID'],
        clienteId: json['clienteId'],
        numeroCuenta: json['numeroCuenta'],
        saldo: (json['saldo'] as num).toDouble(),
      );
}
