alter table catalog_products
    add column default_unit varchar(255);

alter table catalog_products
    add column default_quantity integer;
