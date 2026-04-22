class RegisterWalletRequest {
  final String identificacion;
  final String numeroCuenta;
  final String telefono;

  RegisterWalletRequest({
    required this.identificacion,
    required this.numeroCuenta,
    required this.telefono,
  });

  Map<String, dynamic> toJson() => {
        'identificacion': identificacion,
        'numeroCuenta': numeroCuenta,
        'telefono': telefono,
      };
}
