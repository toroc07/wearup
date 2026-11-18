-- =============================================================================
-- WearUp · 03_datos_prueba.sql
-- Datos de prueba: configuración, categorías, 5 productos con sus variantes
-- (talla + color + stock) y 2 pedidos de ejemplo.
-- Ejecutar después de 02_seguridad.sql. Se puede volver a ejecutar sin duplicar datos.
-- =============================================================================

-- Configuración de la tienda (llave BRE-B de prueba)
insert into public.store_settings (id, promo_active, promo_percent, shipping_cost, bre_b_key, bre_b_holder)
values (1, true, 30, 9900, '300 123 4567', 'WearUp SAS')
on conflict (id) do nothing;

-- Categorías (SRS 1.2)
insert into public.categories (id, name, position) values
  (1, 'Ropa', 1),
  (2, 'Jeans', 2),
  (3, 'Zapatos', 3),
  (4, 'Accesorios', 4)
on conflict (id) do nothing;

-- Productos (ids fijos para poder referenciarlos abajo)
insert into public.products (id, category_id, name, description, price, tint) values
  ('a0000000-0000-4000-8000-000000000001', 1, 'Chaqueta denim',
   'Chaqueta de denim con corte clásico. Algodón de 12 oz, ajuste regular. Lavar a máquina en frío.', 149900, '#D3E2F0'),
  ('a0000000-0000-4000-8000-000000000002', 1, 'Camiseta básica',
   '100 % algodón peinado, cuello redondo y tejido suave. Ideal para el día a día.', 59900, '#E3EAF4'),
  ('a0000000-0000-4000-8000-000000000003', 2, 'Jeans slim',
   'Jeans de corte slim con elastano para mayor comodidad. Tiro medio.', 119900, '#D9E7F2'),
  ('a0000000-0000-4000-8000-000000000004', 3, 'Tenis urbanos',
   'Tenis de suela ligera y plantilla acolchada para uso diario.', 189900, '#DDEBEA'),
  ('a0000000-0000-4000-8000-000000000005', 4, 'Bolso de mano',
   'Bolso de mano en cuero sintético con cierre y bolsillo interior.', 99900, '#D5EBF1')
on conflict (id) do nothing;

-- Variantes: cada combinación color x talla con su SKU y stock.
-- sku = WU-<producto>-<color>-<talla>
with colors (product_id, code, color_name, color_hex, color_order) as (
  values
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'CHQ', 'Azul',   '#3B5B8F', 1),
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'CHQ', 'Negro',  '#1A2433', 2),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'CAM', 'Blanco', '#F2F2F2', 1),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'CAM', 'Negro',  '#1A2433', 2),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'CAM', 'Azul',   '#3B5B8F', 3),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'CAM', 'Verde',  '#4F8F6B', 4),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'CAM', 'Gris',   '#9AA5B1', 5),
    ('a0000000-0000-4000-8000-000000000003'::uuid, 'JNS', 'Negro',  '#1A2433', 1),
    ('a0000000-0000-4000-8000-000000000003'::uuid, 'JNS', 'Azul',   '#3B5B8F', 2),
    ('a0000000-0000-4000-8000-000000000003'::uuid, 'JNS', 'Gris',   '#9AA5B1', 3),
    ('a0000000-0000-4000-8000-000000000004'::uuid, 'TEN', 'Blanco', '#F2F2F2', 1),
    ('a0000000-0000-4000-8000-000000000004'::uuid, 'TEN', 'Negro',  '#1A2433', 2),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'BOL', 'Negro',  '#1A2433', 1),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'BOL', 'Café',   '#8B5E3C', 2),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'BOL', 'Beige',  '#D9C7A8', 3),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'BOL', 'Azul',   '#3B5B8F', 4)
),
sizes (product_id, size, size_order) as (
  values
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'S', 1), ('a0000000-0000-4000-8000-000000000001'::uuid, 'M', 2),
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'L', 3), ('a0000000-0000-4000-8000-000000000001'::uuid, 'XL', 4),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'S', 1), ('a0000000-0000-4000-8000-000000000002'::uuid, 'M', 2),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'L', 3), ('a0000000-0000-4000-8000-000000000002'::uuid, 'XL', 4),
    ('a0000000-0000-4000-8000-000000000003'::uuid, '28', 1), ('a0000000-0000-4000-8000-000000000003'::uuid, '30', 2),
    ('a0000000-0000-4000-8000-000000000003'::uuid, '32', 3), ('a0000000-0000-4000-8000-000000000003'::uuid, '34', 4),
    ('a0000000-0000-4000-8000-000000000004'::uuid, '38', 1), ('a0000000-0000-4000-8000-000000000004'::uuid, '39', 2),
    ('a0000000-0000-4000-8000-000000000004'::uuid, '40', 3), ('a0000000-0000-4000-8000-000000000004'::uuid, '41', 4),
    ('a0000000-0000-4000-8000-000000000004'::uuid, '42', 5),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'Único', 1)
)
insert into public.product_variants (product_id, sku, color_name, color_hex, size, color_order, size_order, stock)
select c.product_id,
       'WU-' || c.code || '-' || upper(left(translate(c.color_name, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU'), 3))
             || '-' || replace(s.size, 'Único', 'U'),
       c.color_name, c.color_hex, s.size, c.color_order, s.size_order,
       case c.code
         when 'CHQ' then 3                                                     -- 24 unidades en total
         when 'CAM' then 3                                                     -- 60 unidades
         when 'JNS' then case when c.color_name = 'Negro' and s.size in ('30', '32', '34') then 1 else 0 end
                                                                               -- 3 unidades: "Últimas unidades"
         when 'TEN' then 2                                                     -- 20 unidades
         else 0                                                                -- bolso agotado
       end
  from colors c
  join sizes s on s.product_id = c.product_id
on conflict (product_id, color_name, size) do nothing;

-- Pedidos de ejemplo (sin cliente asociado: solo los ve el administrador)
insert into public.orders (id, user_id, customer_name, customer_email, phone, address, city, department,
                           subtotal, shipping, status, receipt_path, paid, paid_at, created_at)
overriding system value
values
  (1009, null, 'Cliente de ejemplo', 'cliente@ejemplo.com', '3000000000', 'Calle 45 # 12-30', 'Bogotá', 'Cundinamarca',
   269800, 0, 'delivered', null, true, '2026-09-02 10:00-05', '2026-09-02 09:00-05'),
  (1024, null, 'Cliente de ejemplo', 'cliente@ejemplo.com', '3000000000', 'Calle 45 # 12-30', 'Bogotá', 'Cundinamarca',
   59900, 0, 'shipped', null, true, '2026-09-18 10:00-05', '2026-09-18 09:00-05')
on conflict (id) do nothing;

insert into public.order_items (order_id, product_id, variant_id, product_name, color_name, color_hex, size, tint, unit_price, quantity)
select o.order_id, p.id, v.id, p.name, v.color_name, v.color_hex, v.size, p.tint, p.price, o.quantity
  from (values
          (1009::bigint, 'a0000000-0000-4000-8000-000000000001'::uuid, 'Azul',   'M',  1),
          (1009::bigint, 'a0000000-0000-4000-8000-000000000003'::uuid, 'Negro',  '32', 1),
          (1024::bigint, 'a0000000-0000-4000-8000-000000000002'::uuid, 'Blanco', 'M',  1)
       ) as o (order_id, product_id, color_name, size, quantity)
  join public.products p on p.id = o.product_id
  join public.product_variants v on v.product_id = o.product_id and v.color_name = o.color_name and v.size = o.size
 where not exists (select 1 from public.order_items i where i.order_id = o.order_id);

-- -----------------------------------------------------------------------------
-- Crear el administrador (hacerlo DESPUÉS de registrar la cuenta):
--   1. Regístrate en la app (o en Authentication > Users > Add user, marcando
--      "Auto Confirm User").
--   2. Ejecuta, cambiando el correo:
--
--   update public.profiles set role = 'admin' where email = 'admin@wearup.com';
-- -----------------------------------------------------------------------------
