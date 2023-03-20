create table analysis.dm_rfm_segments
(
    user_id        int4 references production.users (id),
    recency        int2 not null check (recency >= 1 and recency <= 5),
    frequency      int2 not null check (recency >= 1 and recency <= 5),
    monetary_value int2 not null check (recency >= 1 and recency <= 5)
);
