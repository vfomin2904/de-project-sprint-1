insert into analysis.dm_rfm_segments(user_id, recency, frequency, monetary_value)
select r.user_id, r.recency, f.frequency, m.monetary_value
from analysis.tmp_rfm_recency r
         full join analysis.tmp_rfm_frequency f on r.user_id = f.user_id
         full join analysis.tmp_rfm_monetary_value m on m.user_id = f.user_id;


select * from analysis.dm_rfm_segments  order by user_id limit 10;

-- user_id recency frequency monetary_value
-- 0          1	       4	       4
-- 1	      4	       4	       3
-- 2	      2	       3	       5
-- 3	      2	       3	       3
-- 4	      4	       3	       3
-- 5	      5	       5	       5
-- 6	      1	       3	       5
-- 7	      4	       2	       2
-- 8	      1	       2	       3
-- 9	      1	       3	       2