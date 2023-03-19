create
or replace view analysis.orders as (
with order_status as(
select o.order_id, s.status_id, row_number() over(partition by o.order_id order by s.dttm desc) as rn from production.orders o
inner join production.orderstatuslog  s on o.order_id  = s.order_id
)
select o.order_id,  os.status_id from
production.orders o
inner join order_status os on o.order_id = os.order_id and rn = 1
order by order_id;
);
