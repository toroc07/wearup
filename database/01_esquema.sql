-- =============================================================================
-- WearUp · 01_esquema.sql
-- Tablas, relaciones, índices y disparadores (triggers) de la base de datos.
--
-- Ejecutar en el SQL Editor de Supabase sobre un proyecto NUEVO, en este orden:
--   01_esquema.sql  ->  02_seguridad.sql  ->  03_datos_prueba.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Tipos
-- -----------------------------------------------------------------------------

-- Estados de un pedido (RF-007): confirmado -> en preparación -> enviado -> entregado
create type public.order_status as enum ('confirmed', 'preparing', 'shipped', 'delivered');

-- Roles de usuario (SRS 2.3). El cliente invitado no tiene cuenta, así que no tiene rol.
create type public.user_role as enum ('customer', 'admin');

-- -----------------------------------------------------------------------------
-- Función común: mantiene updated_at al día
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Configuración de la tienda (una sola fila)
-- Promoción del inicio, costo de envío y datos de la llave BRE-B.
-- -----------------------------------------------------------------------------
create table public.store_settings (
  id              smallint primary key default 1 check (id = 1),
  promo_active    boolean  not null default true,
  promo_percent   smallint not null default 30 check (promo_percent between 5 and 70),
  shipping_cost   integer  not null default 9900 check (shipping_cost >= 0),
  bre_b_key       text     not null,
  bre_b_holder    text     not null,
  updated_at      timestamptz not null default now()
);

create trigger store_settings_updated_at
  before update on public.store_settings
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Catálogo (RF-003, RF-004, RF-008)
-- -----------------------------------------------------------------------------
create table public.categories (
  id        smallint primary key,
  name      text     not null unique,
  position  smallint not null default 0
);

create table public.products (
  id           uuid        primary key default gen_random_uuid(),
  category_id  smallint    not null references public.categories (id) on update cascade,
  name         text        not null check (length(trim(name)) > 0),
  description  text        not null default '',
  price        integer     not null check (price >= 0),          -- pesos colombianos, sin decimales
  tint         text        not null default '#D3E2F0'            -- color de fondo mientras no hay foto
                           check (tint ~ '^#[0-9A-Fa-f]{6}$'),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index products_category_idx on public.products (category_id);

create trigger products_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

-- Variante = combinación talla + color de un producto, con su propio SKU y stock
-- (SRS 1.3: el inventario se lleva por variante).
create table public.product_variants (
  id           uuid     primary key default gen_random_uuid(),
  product_id   uuid     not null references public.products (id) on delete cascade,
  sku          text     not null unique,
  color_name   text     not null,
  color_hex    text     not null check (color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  size         text     not null,
  color_order  smallint not null default 0,   -- orden de los colores en la ficha
  size_order   smallint not null default 0,   -- orden de las tallas (S, M, L... / 28, 30...)
  stock        integer  not null default 0 check (stock >= 0),
  unique (product_id, color_name, size)
);

create index product_variants_product_idx on public.product_variants (product_id);

-- Fotos de un producto (archivos en el bucket público "product-images")
create table public.product_images (
  id          uuid     primary key default gen_random_uuid(),
  product_id  uuid     not null references public.products (id) on delete cascade,
  path        text     not null unique,    -- ruta dentro del bucket
  position    smallint not null default 0
);

create index product_images_product_idx on public.product_images (product_id);

-- -----------------------------------------------------------------------------
-- Usuarios (RF-001, RF-002)
-- La cuenta (correo y contraseña cifrada) la maneja Supabase Auth en auth.users;
-- aquí se guardan los datos del perfil y el rol.
-- -----------------------------------------------------------------------------
create table public.profiles (
  id               uuid        primary key references auth.users (id) on delete cascade,
  email            text        not null,
  full_name        text        not null default '',
  phone            text        not null default '',
  role             public.user_role not null default 'customer',
  -- Autorización de tratamiento de datos personales (Ley 1581 de 2012)
  data_consent_at  timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Crea el perfil automáticamente cuando alguien se registra.
-- La app envía full_name, phone y data_consent en los metadatos del registro.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, phone, data_consent_at)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(coalesce(new.email, ''), '@', 1)),
    coalesce(trim(new.raw_user_meta_data ->> 'phone'), ''),
    case when (new.raw_user_meta_data ->> 'data_consent') = 'true' then now() end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- Pedidos (RF-006, RF-007, RF-008)
-- -----------------------------------------------------------------------------
create table public.orders (
  -- El número de pedido que ve el cliente (#1032, #1033...)
  id              bigint      generated by default as identity (start with 1032) primary key,
  user_id         uuid        references public.profiles (id) on delete set null,
  customer_name   text        not null,
  customer_email  text        not null default '',
  phone           text        not null,
  address         text        not null,
  city            text        not null,
  department      text        not null,
  notes           text        not null default '',
  subtotal        integer     not null check (subtotal >= 0),
  shipping        integer     not null check (shipping >= 0),
  total           integer     generated always as (subtotal + shipping) stored,
  status          public.order_status not null default 'confirmed',
  -- Pago por llave BRE-B: el cliente sube la captura y el administrador la valida
  receipt_path    text,                       -- ruta en el bucket privado "receipts"
  paid            boolean     not null default false,
  paid_at         timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index orders_user_idx on public.orders (user_id);
create index orders_status_idx on public.orders (status);
create index orders_created_idx on public.orders (created_at desc);

create trigger orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

-- Registra cuándo se validó el pago
create or replace function public.set_paid_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.paid and not old.paid then
    new.paid_at := now();
  elsif not new.paid then
    new.paid_at := null;
  end if;
  return new;
end;
$$;

create trigger orders_paid_at
  before update of paid on public.orders
  for each row execute function public.set_paid_at();

-- Ítems de un pedido. Guardan una copia del producto (nombre, precio, color, talla)
-- para que el pedido no cambie si luego se edita o elimina el producto.
create table public.order_items (
  id           bigint   generated always as identity primary key,
  order_id     bigint   not null references public.orders (id) on delete cascade,
  product_id   uuid     references public.products (id) on delete set null,
  variant_id   uuid     references public.product_variants (id) on delete set null,
  product_name text     not null,
  color_name   text     not null,
  color_hex    text     not null,
  size         text     not null,
  tint         text     not null default '#D3E2F0',
  unit_price   integer  not null check (unit_price >= 0),
  quantity     integer  not null check (quantity > 0),
  line_total   integer  generated always as (unit_price * quantity) stored
);

create index order_items_order_idx on public.order_items (order_id);
create index order_items_variant_idx on public.order_items (variant_id);
create index order_items_product_idx on public.order_items (product_id);

-- -----------------------------------------------------------------------------
-- Row Level Security activado desde el inicio: hasta que 02_seguridad.sql cree
-- las políticas, nadie puede leer ni escribir estas tablas desde la app.
-- -----------------------------------------------------------------------------
alter table public.store_settings   enable row level security;
alter table public.categories       enable row level security;
alter table public.products         enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_images   enable row level security;
alter table public.profiles         enable row level security;
alter table public.orders           enable row level security;
alter table public.order_items      enable row level security;
