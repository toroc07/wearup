// Conexión con el proyecto Supabase de WearUp.
//
// La clave publicable es pública por diseño: viaja dentro de la app y solo
// permite lo que autorizan los permisos de la base (database/02_seguridad.sql).
// La clave secreta NUNCA va en la app ni en el repositorio.
//
// Para usar otro proyecto:
//   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://ymvqkvuamtyqanenenuc.supabase.co',
);

const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_imjnqa0jd7hCd6mB99uZiw_uUaHJ6SZ',
);
