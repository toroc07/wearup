import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

// Política de tratamiento de datos personales (Ley 1581 de 2012 y Decreto 1377 de 2013).
// BORRADOR para revisión del equipo: no es asesoría legal.
const _sections = [
  (
    'Responsable',
    'WearUp (proyecto académico de la materia Desarrollo de Software) es responsable del tratamiento de los datos '
        'personales que recoge esta aplicación.',
  ),
  (
    'Datos que recogemos',
    '• Al crear tu cuenta: nombre, correo electrónico, teléfono y contraseña (guardada cifrada; nadie de WearUp puede verla).\n'
        '• Al comprar: nombre de quien recibe, teléfono, dirección de entrega, ciudad, departamento, indicaciones y la '
        'captura del comprobante de la transferencia.\n'
        '• No recogemos datos de tarjetas ni claves bancarias.',
  ),
  (
    'Para qué los usamos',
    '• Crear y administrar tu cuenta.\n'
        '• Procesar tus pedidos, validar el pago y enviarte los productos.\n'
        '• Informarte el estado de tus pedidos.\n'
        'No vendemos ni compartimos tus datos con terceros para publicidad.',
  ),
  (
    'Cómo los protegemos',
    'Los datos viajan cifrados (HTTPS) y se guardan en una base de datos cifrada. Cada cliente solo puede ver su '
        'información y sus pedidos; los comprobantes de pago se guardan en un espacio privado al que solo acceden el '
        'cliente y el administrador de la tienda.',
  ),
  (
    'Tus derechos',
    'Como titular puedes conocer, actualizar y rectificar tus datos, solicitar prueba de la autorización, ser '
        'informado sobre su uso, revocar la autorización o pedir que se eliminen, y presentar quejas ante la '
        'Superintendencia de Industria y Comercio (SIC).',
  ),
  (
    'Cómo ejercerlos',
    'Desde Cuenta > Mis datos puedes actualizar tu nombre y teléfono, y eliminar tu cuenta. Al eliminarla se borran '
        'tu cuenta y tu perfil; los pedidos ya realizados se conservan como soporte de la venta, sin vínculo con tu cuenta.',
  ),
  (
    'Autorización',
    'Al crear tu cuenta y marcar la casilla de autorización aceptas el tratamiento de tus datos para las finalidades '
        'descritas. Guardamos la fecha en que diste la autorización.',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Política de privacidad')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Tratamiento de datos personales', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kNavy)),
        const SizedBox(height: 6),
        const Text('Ley 1581 de 2012 · Decreto 1377 de 2013', style: TextStyle(color: kMuted)),
        const SizedBox(height: 16),
        for (final (title, body) in _sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card2(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.4)),
              ]),
            ),
          ),
      ]),
    );
  }
}
