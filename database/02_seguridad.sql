-- WearUp: permisos (RLS), funciones del servidor y almacenamiento.

-- ¿El usuario actual es administrador?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

-- Privilegios por tabla
revoke all on all tables in schema public from anon, authenticated;

grant select on public.categories, public.products, public.product_variants,
                public.product_images, public.store_settings
  to anon, authenticated;

grant insert, update, delete on public.categories, public.products,
                                public.product_variants, public.product_images
  to authenticated;
grant update on public.store_settings to authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

grant select on public.orders, public.order_items to authenticated;
grant update (status, paid) on public.orders to authenticated;

-- Row Level Security
alter table public.store_settings   enable row level security;
alter table public.categories       enable row level security;
alter table public.products         enable row level security;
alter table public.product_variants enable row level security;
alter table public.product_images   enable row level security;
alter table public.profiles         enable row level security;
alter table public.orders           enable row level security;
alter table public.order_items      enable row level security;

create policy "Todos leen la configuración" on public.store_settings
  for select to anon, authenticated using (true);
create policy "El administrador cambia la configuración" on public.store_settings
  for update to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Todos leen las categorías" on public.categories
  for select to anon, authenticated using (true);
create policy "El administrador gestiona las categorías" on public.categories
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Todos leen los productos" on public.products
  for select to anon, authenticated using (true);
create policy "El administrador gestiona los productos" on public.products
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Todos leen las variantes" on public.product_variants
  for select to anon, authenticated using (true);
create policy "El administrador gestiona las variantes" on public.product_variants
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Todos leen las fotos" on public.product_images
  for select to anon, authenticated using (true);
create policy "El administrador gestiona las fotos" on public.product_images
  for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Cada usuario ve su perfil y el administrador ve todos" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));
create policy "Cada usuario edita su perfil" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "El cliente ve sus pedidos y el administrador todos" on public.orders
  for select to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));
create policy "El administrador actualiza los pedidos" on public.orders
  for update to authenticated
  using ((select public.is_admin())) with check ((select public.is_admin()));

create policy "Ítems visibles si el pedido es visible" on public.order_items
  for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.id = order_id
      and (o.user_id = (select auth.uid()) or (select public.is_admin()))
  ));

-- place_order: crea el pedido validando stock y precios en el servidor. p_items = [{"variant_id": uuid, "quantity": n}]
create or replace function public.place_order(
  p_items          jsonb,
  p_customer_name  text,
  p_phone          text,
  p_address        text,
  p_city           text,
  p_department     text,
  p_notes          text,
  p_receipt_path   text
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user       uuid := auth.uid();
  v_email      text;
  v_order_id   bigint;
  v_shipping   integer;
  v_requested  integer;
  v_found      integer;
  v_subtotal   bigint;
  v_bad_qty    boolean;
  v_no_stock   boolean;
begin
  if v_user is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'CARRITO_VACIO' using errcode = '22023';
  end if;

  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_address), '') = ''
     or coalesce(trim(p_city), '') = '' or coalesce(trim(p_department), '') = '' then
    raise exception 'DATOS_ENVIO_INCOMPLETOS' using errcode = '22023';
  end if;

  if length(regexp_replace(coalesce(p_phone, ''), '\D', '', 'g')) < 7 then
    raise exception 'TELEFONO_INVALIDO' using errcode = '22023';
  end if;

  if p_receipt_path is null
     or split_part(p_receipt_path, '/', 1) <> v_user::text
     or not exists (select 1 from storage.objects
                    where bucket_id = 'receipts' and name = p_receipt_path) then
    raise exception 'COMPROBANTE_INVALIDO' using errcode = '22023';
  end if;

  perform 1 from public.product_variants
   where id in (select x.variant_id from jsonb_to_recordset(p_items) as x(variant_id uuid, quantity integer))
   order by id
   for update;

  select count(*), count(v.id), coalesce(sum(p.price::bigint * r.qty), 0),
         coalesce(bool_or(r.qty is null or r.qty <= 0 or r.qty > 1000), false),
         coalesce(bool_or(r.qty > v.stock), false)
    into v_requested, v_found, v_subtotal, v_bad_qty, v_no_stock
    from (select x.variant_id, sum(x.quantity)::integer as qty
            from jsonb_to_recordset(p_items) as x(variant_id uuid, quantity integer)
           group by x.variant_id) r
    left join public.product_variants v on v.id = r.variant_id
    left join public.products p on p.id = v.product_id;

  if v_bad_qty then
    raise exception 'CANTIDAD_INVALIDA' using errcode = '22023';
  end if;
  if v_found < v_requested then
    raise exception 'PRODUCTO_NO_DISPONIBLE' using errcode = '22023';
  end if;
  if v_no_stock then
    raise exception 'STOCK_INSUFICIENTE' using errcode = '22023';
  end if;

  select shipping_cost into v_shipping from public.store_settings where id = 1;
  select email into v_email from public.profiles where id = v_user;

  insert into public.orders (user_id, customer_name, customer_email, phone, address, city,
                             department, notes, subtotal, shipping, receipt_path)
  values (v_user, trim(p_customer_name), coalesce(v_email, ''), trim(p_phone), trim(p_address),
          trim(p_city), trim(p_department), coalesce(trim(p_notes), ''),
          v_subtotal::integer, coalesce(v_shipping, 0), p_receipt_path)
  returning id into v_order_id;

  insert into public.order_items (order_id, product_id, variant_id, product_name, color_name,
                                  color_hex, size, tint, unit_price, quantity)
  select v_order_id, p.id, v.id, p.name, v.color_name, v.color_hex, v.size, p.tint, p.price, r.qty
    from (select x.variant_id, sum(x.quantity)::integer as qty
            from jsonb_to_recordset(p_items) as x(variant_id uuid, quantity integer)
           group by x.variant_id) r
    join public.product_variants v on v.id = r.variant_id
    join public.products p on p.id = v.product_id;

  update public.product_variants v
     set stock = v.stock - r.qty
    from (select x.variant_id, sum(x.quantity)::integer as qty
            from jsonb_to_recordset(p_items) as x(variant_id uuid, quantity integer)
           group by x.variant_id) r
   where v.id = r.variant_id;

  return v_order_id;
end;
$$;

-- delete_order: si el pedido no se entregó, devuelve las unidades al inventario
create or replace function public.delete_order(p_order_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status public.order_status;
begin
  if not public.is_admin() then
    raise exception 'SOLO_ADMIN' using errcode = '42501';
  end if;

  select status into v_status from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'PEDIDO_NO_EXISTE' using errcode = '22023';
  end if;

  if v_status <> 'delivered' then
    update public.product_variants v
       set stock = v.stock + i.qty
      from (select variant_id, sum(quantity)::integer as qty
              from public.order_items
             where order_id = p_order_id and variant_id is not null
             group by variant_id) i
     where v.id = i.variant_id;
  end if;

  delete from public.orders where id = p_order_id;
end;
$$;

-- delete_my_account: el usuario elimina su cuenta (los pedidos se conservan)
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'NO_AUTENTICADO' using errcode = '42501';
  end if;
  delete from auth.users where id = v_user;
end;
$$;

revoke execute on all functions in schema public from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.place_order(jsonb, text, text, text, text, text, text, text) to authenticated;
grant execute on function public.delete_order(bigint) to authenticated;
grant execute on function public.delete_my_account() to authenticated;

-- Almacenamiento: fotos de productos (público) y comprobantes (privado, carpeta por cliente)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 10485760, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

create policy "El administrador sube fotos de productos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and (select public.is_admin()));
create policy "El administrador cambia fotos de productos" on storage.objects
  for update to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));
create policy "El administrador borra fotos de productos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and (select public.is_admin()));

create policy "El cliente sube su comprobante" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'receipts'
              and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "El cliente ve sus comprobantes y el administrador todos" on storage.objects
  for select to authenticated
  using (bucket_id = 'receipts'
         and ((storage.foldername(name))[1] = (select auth.uid()::text) or (select public.is_admin())));
create policy "El administrador borra comprobantes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'receipts' and (select public.is_admin()));
