import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend.dart';
import 'models.dart';

/// Backend real: Supabase (Postgres + Auth + Storage).
/// Los permisos los aplica la base de datos (RLS); ver database/02_seguridad.sql.
class SupabaseBackend implements Backend {
  SupabaseClient get _db => Supabase.instance.client;

  // Convierte cualquier error en un mensaje entendible
  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on BackendException {
      rethrow;
    } on AuthException catch (e) {
      throw BackendException(_authMessage(e));
    } on PostgrestException catch (e) {
      throw BackendException(serverErrors[e.message] ?? _postgrestMessage(e));
    } on StorageException catch (e) {
      throw BackendException(e.statusCode == '413' ? 'La imagen supera el tamaño máximo.' : 'No se pudo guardar la imagen (${e.message}).');
    } catch (_) {
      throw const BackendException('No se pudo conectar con el servidor. Revisa tu conexión a internet.');
    }
  }

  String _authMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak_password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'email_address_invalid':
        return 'Ingresa un correo válido.';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de ingresar.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';
      case 'otp_expired':
        return 'El código no es válido o ya venció.';
      case 'same_password':
        return 'La nueva contraseña debe ser distinta de la anterior.';
      case 'signup_disabled':
      case 'email_provider_disabled':
        return 'El registro de cuentas nuevas está desactivado en este momento.';
    }
    return 'No se pudo completar la operación (${e.message}).';
  }

  String _postgrestMessage(PostgrestException e) {
    if (e.code == '42501') return 'No tienes permiso para hacer esto.';
    if (e.code == '23505') return 'Ya existe un registro con esos datos.';
    if (e.code == '23514') return 'Hay un valor fuera del rango permitido.';
    return 'Error del servidor: ${e.message}';
  }

  // Con RLS, un cambio no permitido no da error: simplemente no afecta filas.
  // Si no cambió nada, se avisa en vez de fingir que se guardó.
  void _changed(List<dynamic> rows) {
    if (rows.isEmpty) throw const BackendException('No tienes permiso para hacer esto o el registro ya no existe.');
  }

  // ---------------------------------------------------------------- Catálogo

  @override
  Future<CatalogData> loadCatalog() => _call(() async {
        final results = await Future.wait([
          // Ojo: order() es descendente por defecto en este SDK
          _db.from('categories').select().order('position', ascending: true),
          _db
              .from('products')
              .select('*, product_variants(*), product_images(*)')
              .order('created_at', ascending: true)
              .order('id', ascending: true),
          _db.from('store_settings').select().eq('id', 1).maybeSingle(),
        ]);
        final categories = [for (final c in results[0] as List) ProductCategory.fromJson(c as Map<String, dynamic>)];
        final products = [for (final p in results[1] as List) Product.fromJson(p as Map<String, dynamic>)];
        final settings = results[2] == null ? const StoreSettings() : StoreSettings.fromJson(results[2] as Map<String, dynamic>);
        return CatalogData(categories, products, settings);
      });

  @override
  String productImageUrl(String path) => _db.storage.from('product-images').getPublicUrl(path);

  // ---------------------------------------------------------------- Sesión

  Future<Profile?> _fetchProfile(String userId) async {
    final row = await _db.from('profiles').select().eq('id', userId).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  @override
  Future<Profile?> currentProfile() => _call(() async {
        final user = _db.auth.currentUser;
        if (user == null) return null;
        final profile = await _fetchProfile(user.id);
        // La cuenta ya no existe (por ejemplo, se eliminó): se cierra la sesión guardada
        if (profile == null) await _db.auth.signOut();
        return profile;
      });

  @override
  Future<Profile> signIn(String email, String password) => _call(() async {
        final res = await _db.auth.signInWithPassword(email: email, password: password);
        final profile = await _fetchProfile(res.user!.id);
        if (profile == null) throw const BackendException('No encontramos el perfil de esta cuenta.');
        return profile;
      });

  @override
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required bool dataConsent,
  }) =>
      _call(() async {
        final res = await _db.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'phone': phone, 'data_consent': dataConsent},
        );
        if (res.session == null) {
          throw const BackendException('Te enviamos un correo para confirmar tu cuenta. Confírmala y luego ingresa.');
        }
        final profile = await _fetchProfile(res.user!.id);
        if (profile == null) throw const BackendException('No se pudo crear el perfil.');
        return profile;
      });

  @override
  Future<void> signOut() => _call(() => _db.auth.signOut());

  @override
  Future<void> sendPasswordReset(String email) => _call(() => _db.auth.resetPasswordForEmail(email));

  @override
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) =>
      _call(() async {
        await _db.auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
        await _db.auth.updateUser(UserAttributes(password: newPassword));
        // Se cierra la sesión de recuperación para que ingrese con la nueva contraseña
        await _db.auth.signOut();
      });

  @override
  Future<Profile> updateProfile({required String fullName, required String phone}) => _call(() async {
        final user = _db.auth.currentUser;
        if (user == null) throw BackendException(serverErrors['NO_AUTENTICADO']!);
        final row = await _db.from('profiles').update({'full_name': fullName, 'phone': phone}).eq('id', user.id).select().single();
        return Profile.fromJson(row);
      });

  @override
  Future<void> deleteMyAccount() => _call(() async {
        await _db.rpc('delete_my_account');
        await _db.auth.signOut();
      });

  // ---------------------------------------------------------------- Pedidos

  @override
  Future<List<Order>> loadOrders() => _call(() async {
        final rows = await _db.from('orders').select('*, order_items(*)').order('created_at', ascending: false);
        return [for (final o in rows) Order.fromJson(o)];
      });

  @override
  Future<String> uploadReceipt(PickedImage image) => _call(() async {
        final user = _db.auth.currentUser;
        if (user == null) throw BackendException(serverErrors['NO_AUTENTICADO']!);
        final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${image.extension}';
        await _db.storage.from('receipts').uploadBinary(path, image.bytes, fileOptions: FileOptions(contentType: image.contentType));
        return path;
      });

  @override
  Future<int> placeOrder({required List<CartItem> items, required ShippingInfo shipping, required String receiptPath}) =>
      _call(() async {
        final id = await _db.rpc('place_order', params: {
          'p_items': [
            for (final i in items) {'variant_id': i.variant.id, 'quantity': i.qty},
          ],
          'p_customer_name': shipping.customerName,
          'p_phone': shipping.phone,
          'p_address': shipping.address,
          'p_city': shipping.city,
          'p_department': shipping.department,
          'p_notes': shipping.notes,
          'p_receipt_path': receiptPath,
        });
        return (id as num).toInt();
      });

  @override
  Future<String> receiptUrl(String path) => _call(() => _db.storage.from('receipts').createSignedUrl(path, 600));

  // ---------------------------------------------------------------- Administración

  // Parte legible del SKU: sin tildes, espacios ni símbolos
  static String _code(String s) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  @override
  Future<String> saveProduct(ProductDraft draft) => _call(() async {
        final row = {
          'name': draft.name,
          'category_id': draft.categoryId,
          'description': draft.description,
          'price': draft.price,
          'tint': draft.tint,
        };
        final String id;
        if (draft.id == null) {
          id = (await _db.from('products').insert(row).select('id').single())['id'] as String;
        } else {
          id = draft.id!;
          _changed(await _db.from('products').update(row).eq('id', id).select('id'));
        }

        // Variantes: se conservan las que siguen (con su stock), se crean las nuevas y se borran las que sobran
        final existing = await _db.from('product_variants').select('id, sku, color_name, size').eq('product_id', id);
        final keep = <String>{};
        final updates = <Map<String, dynamic>>[];
        final inserts = <Map<String, dynamic>>[];
        for (var ci = 0; ci < draft.colors.length; ci++) {
          for (var si = 0; si < draft.sizes.length; si++) {
            final color = draft.colors[ci], size = draft.sizes[si];
            final data = {
              'product_id': id,
              'color_name': color.name,
              'color_hex': color.hex,
              'size': size,
              'color_order': ci + 1,
              'size_order': si + 1,
            };
            final match = existing.where((v) => v['color_name'] == color.name && v['size'] == size);
            if (match.isNotEmpty) {
              keep.add(match.first['id'] as String);
              updates.add({...data, 'id': match.first['id'], 'sku': match.first['sku']});
            } else {
              inserts.add({...data, 'sku': 'WU-${id.substring(0, 8).toUpperCase()}-${_code(color.name)}-${_code(size)}', 'stock': 0});
            }
          }
        }
        final remove = [for (final v in existing) if (!keep.contains(v['id'])) v['id'] as String];
        if (remove.isNotEmpty) await _db.from('product_variants').delete().inFilter('id', remove);
        if (updates.isNotEmpty) await _db.from('product_variants').upsert(updates);
        if (inserts.isNotEmpty) await _db.from('product_variants').insert(inserts);
        return id;
      });

  @override
  Future<void> deleteProduct(String productId) => _call(() async {
        final images = await _db.from('product_images').select('path').eq('product_id', productId);
        final paths = [for (final i in images) i['path'] as String];
        if (paths.isNotEmpty) await _db.storage.from('product-images').remove(paths);
        _changed(await _db.from('products').delete().eq('id', productId).select('id'));
      });

  @override
  Future<void> setVariantStock(String variantId, int stock) =>
      _call(() async => _changed(await _db.from('product_variants').update({'stock': stock}).eq('id', variantId).select('id')));

  @override
  Future<void> addProductImage(String productId, PickedImage image) => _call(() async {
        final path = '$productId/${DateTime.now().millisecondsSinceEpoch}.${image.extension}';
        await _db.storage.from('product-images').uploadBinary(path, image.bytes, fileOptions: FileOptions(contentType: image.contentType));
        final count = await _db.from('product_images').select('id').eq('product_id', productId);
        await _db.from('product_images').insert({'product_id': productId, 'path': path, 'position': count.length});
      });

  @override
  Future<void> deleteProductImage(String productId, String path) => _call(() async {
        await _db.from('product_images').delete().eq('product_id', productId).eq('path', path);
        await _db.storage.from('product-images').remove([path]);
      });

  @override
  Future<void> updateOrder(int orderId, {OrderStatus? status, bool? paid}) => _call(() async {
        _changed(await _db.from('orders').update({
          'status': ?status?.name,
          'paid': ?paid,
        }).eq('id', orderId).select('id'));
      });

  @override
  Future<void> deleteOrder(int orderId) => _call(() => _db.rpc('delete_order', params: {'p_order_id': orderId}));

  @override
  Future<void> saveSettings(StoreSettings settings) => _call(() async {
        _changed(await _db.from('store_settings').update({
          'promo_active': settings.promoActive,
          'promo_percent': settings.promoPercent,
        }).eq('id', 1).select('id'));
      });
}
