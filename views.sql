create or replace view orderitems as (select * from production.orderitems);

create or replace view orders as (select * from production.orders);

create or replace view orderstatuses as (select * from production.orderstatuses);

create or replace view orderstatuslog as (select * from production.orderstatuslog);

create or replace view products as (select * from production.products);

create or replace view users as (select * from production.users);