insert into analysis.tmp_rfm_monetary_value
with last_orders as (select u.id, sum(payment) as order_sum
                     from orders o
                              inner join orderstatuses os on o.status = os.id and os."key" = 'Closed'
                              right join users u on o.user_id = u.id and o.order_ts >= '2022-01-01 00:00:00':: timestamp
group by u.id)
select id,
       (row_number() over(order by order_sum nulls first) - 1) / (select count(*) / 5 from last_orders) + 1 as category
from last_orders;
