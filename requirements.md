# Витрина RFM

## 1.1. Выясните требования к целевой витрине.

Постановка задачи выглядит достаточно абстрактно - постройте витрину. Первым делом вам необходимо выяснить у заказчика детали. Запросите недостающую информацию у заказчика в чате.

Зафиксируйте выясненные требования. Составьте документацию готовящейся витрины на основе заданных вами вопросов, добавив все необходимые детали.

-----------

Целевая витрина необходима для сегментации клиентов, при которой анализируют их лояльность: как часто, на какие суммы и когда в последний раз тот или иной клиент покупал что-то. Витрина должна располагаться в схеме analysis и должна состоять из следующих полей: user_id - id клиента, recency - показатель времени прошедшего с момента последнего заказа,
frequency - количество заказов, monetary_value - сумма затрат клиента. Учесть, что выполненный заказ имеет статус Closed.
Метрики recency, frequency и monetary_value принимают целые значения от 1 до 5. При этом распределение этих значений должно быть равномерным. То есть, если в системе 10 клиентов, то 2 клиента должны получить значение 1, ещё 2 — значение 2 и т. д.
Витрина должна называться dm_rfm_segments и агригировать данные с начала 2022 года. Обновлять витрину не нужно.



## 1.2. Изучите структуру исходных данных.

Полключитесь к базе данных и изучите структуру таблиц.

Если появились вопросы по устройству источника, задайте их в чате.

Зафиксируйте, какие поля вы будете использовать для расчета витрины.

-----------

Таблица orders:
- order_id - id заказа
- order_ts - дата и время заказа
- user_id - id пользователя
- payment - сумма заказа
- status - статус заказа

Таблица order_statuses:
- id - id статуса
- key - название статуса

Таблица users:
- id - id пользователя


## 1.3. Проанализируйте качество данных

Изучите качество входных данных. Опишите, насколько качественные данные хранятся в источнике. Так же укажите, какие инструменты обеспечения качества данных были использованы в таблицах в схеме production.

-----------
Таблица orders:
- Проверка суммы заказа cost = (payment + bonus_payment)
- order_id - primary key
- bonus_payment, payment, cost, bonus_grant, order_ts, user_id - non null
- Не хватает foreign key(user_id) references user(id)

Таблица orderstatuses:
- id - primary key
- key - NOT NULL
- Не хватает foreign key(id) references orders(order_id)

Таблица users:
- id - primary key

Данные заполнены корректно. Несмотря на отсутствие связей между таблицами, данные согласованы.


## 1.4. Подготовьте витрину данных

Теперь, когда требования понятны, а исходные данные изучены, можно приступить к реализации.

### 1.4.1. Сделайте VIEW для таблиц из базы production.**

Вас просят при расчете витрины обращаться только к объектам из схемы analysis. Чтобы не дублировать данные (данные находятся в этой же базе), вы решаете сделать view. Таким образом, View будут находиться в схеме analysis и вычитывать данные из схемы production.

Напишите SQL-запросы для создания пяти VIEW (по одному на каждую таблицу) и выполните их. Для проверки предоставьте код создания VIEW.

```SQL
create or replace view orderitems as (select * from production.orderitems);

create or replace view orders as (select * from production.orders);

create or replace view orderstatuses as (select * from production.orderstatuses);

create or replace view orderstatuslog as (select * from production.orderstatuslog);

create or replace view products as (select * from production.products);

create or replace view users as (select * from production.users);

```

### 1.4.2. Напишите DDL-запрос для создания витрины.**

Далее вам необходимо создать витрину. Напишите CREATE TABLE запрос и выполните его на предоставленной базе данных в схеме analysis.

```SQL
create table dm_rfm_segments (
user_id int4 references production.users(id),
recency int2 not null check(recency >= 1 and recency <= 5),
frequency int2 not null check(recency >= 1 and recency <= 5),
monetary_value int2 not null check(recency >= 1 and recency <= 5)
);

```

### 1.4.3. Напишите SQL запрос для заполнения витрины

Наконец, реализуйте расчет витрины на языке SQL и заполните таблицу, созданную в предыдущем пункте.

Для решения предоставьте код запроса.

```SQL
insert into analysis.tmp_rfm_recency 
with last_orders as (select u.id, max(o.order_ts) as dt from orders o
inner join orderstatuses os on o.status = os.id and os."key" = 'Closed'
right join users u on o.user_id = u.id and o.order_ts >= '2022-01-01 00:00:00'::timestamp
group by u.id)
select id, (row_number() over(order by dt nulls first) - 1) / (select count(*)/5 from last_orders) + 1 as category from last_orders;


insert into analysis.tmp_rfm_frequency 
with last_orders as (select u.id, count(*) as cnt from orders o
inner join orderstatuses os on o.status = os.id and os."key" = 'Closed'
right join users u on o.user_id = u.id and o.order_ts >= '2022-01-01 00:00:00'::timestamp
group by u.id)
select id, (row_number() over(order by cnt nulls first) - 1) / (select count(*)/5 from last_orders) + 1 as category from last_orders;


insert into analysis.tmp_rfm_monetary_value  
with last_orders as (select u.id, sum(payment) as order_sum from orders o
inner join orderstatuses os on o.status = os.id and os."key" = 'Closed'
right join users u on o.user_id = u.id and o.order_ts >= '2022-01-01 00:00:00'::timestamp
group by u.id)
select id, (row_number() over(order by order_sum nulls first) - 1) / (select count(*)/5 from last_orders) + 1 as category from last_orders;


insert into analysis.dm_rfm_segments 
select r.user_id , r.recency, f.frequency, m.monetary_value 
from analysis.tmp_rfm_recency r
full join analysis.tmp_rfm_frequency  f on r.user_id = f.user_id 
full join analysis.tmp_rfm_monetary_value m on m.user_id = f.user_id;


```



