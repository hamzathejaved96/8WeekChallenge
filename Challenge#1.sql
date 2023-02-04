

-- 1.
SELECT  s.customer_id
        ,SUM(m.price) total_amount_spent
FROM    sales s
INNER JOIN menu m
ON      s.product_id = m.product_id
GROUP BY s.customer_id
;

-- 2.
SELECT  customer_id
        ,COUNT(DISTINCT order_date) days_visited
FROM    sales
GROUP BY customer_id
;

-- 3.
WITH sales_cte AS 
(
    SELECT  customer_id
            ,product_id
            ,order_date
            ,DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ) rnk
    FROM    sales
)
SELECT  s.customer_id
        ,s.order_date
        ,m.product_name
FROM    sales_cte s
INNER JOIN menu m
ON      s.product_id = m.product_id
WHERE   rnk = 1
;
-- 4.
WITH
    product_purchase_count_cte as ( SELECT top 1 product_id, count(product_id) purchased_count FROM sales GROUP BY product_id ORDER BY 2 DESC )
    ,most_purchased_product_cte as ( SELECT product_id, product_name FROM menu WHERE product_id = (SELECT product_id FROM product_purchase_count_cte ) )
SELECT  s.customer_id
        ,mp.product_id
        ,mp.product_name
        ,count(mp.product_id) purchase_count
FROM    sales s INNER
JOIN    most_purchased_product_cte mp
ON      s.product_id = mp.product_id
GROUP BY s.customer_id
         ,mp.product_id
         ,mp.product_name
;
-- 5. 
with
    product_count_cte as ( SELECT customer_id, product_id, count(product_id) product_count FROM sales GROUP BY customer_id, product_id )
    ,product_count_rank_cte as ( SELECT customer_id, product_id, product_count, dense_rank() over(PARTITION BY customer_id ORDER BY product_count DESC) rnk FROM product_count_cte )
SELECT  pcr.customer_id
        ,pcr.product_id
        ,concat(product_name, ' (', product_count ,' times)') most_popular_item
FROM    product_count_rank_cte pcr INNER
JOIN    menu m
ON      pcr.product_id = m.product_id
WHERE   rnk = 1
;
-- 6. 

with
    cte as ( SELECT s.customer_id, s.order_date, m.join_date, s.product_id, me.product_name, dense_rank() over(PARTITION BY s.customer_id ORDER BY s.order_date) rn FROM sales s INNER JOIN menu me ON s.product_id = me.product_id INNER JOIN members m ON s.customer_id = m.customer_id WHERE s.order_date >= m.join_date )
SELECT  customer_id
        ,product_name
FROM    cte
WHERE   rn = 1
;
-- 7.

WITH
    cte as ( SELECT s.customer_id, s.order_date, m.join_date, s.product_id, me.product_name, dense_rank() over(PARTITION BY s.customer_id ORDER BY s.order_date DESC) rn FROM sales s INNER JOIN menu me ON s.product_id = me.product_id INNER JOIN members m ON s.customer_id = m.customer_id WHERE s.order_date < m.join_date )
SELECT  customer_id
        ,product_name
FROM    cte
WHERE   rn = 1
;
-- 8. 

with
    cte as ( SELECT s.customer_id, s.order_date, m.join_date, s.product_id, me.price FROM sales s INNER JOIN menu me ON s.product_id = me.product_id INNER JOIN members m ON s.customer_id = m.customer_id WHERE s.order_date < m.join_date )
SELECT  customer_id
        ,count(product_id) total_items
        ,sum(price) total_amount_spent
FROM    cte
GROUP BY customer_id
;
-- 9.  

WITH
    cte as ( SELECT s.customer_id, s.product_id, m.product_name, m.price FROM sales s INNER JOIN menu m ON s.product_id = m.product_id )
SELECT  customer_id
        ,sum(
            CASE    WHEN product_name = 'sushi' THEN price * 20 
                    ELSE price * 10 
            END
        ) total_points
FROM    cte
GROUP BY customer_id
;
-- 10. 

with
    cte as ( SELECT s.customer_id, s.product_id, m.product_name, m.price, s.order_date, me.join_date FROM sales s INNER JOIN menu m ON s.product_id = m.product_id INNER JOIN members me ON s.customer_id = me.customer_id WHERE mONth(s.order_date) = 1 )
SELECT  customer_id
        ,sum(
            CASE    WHEN product_name = 'sushi' THEN price * 20
                    WHEN order_date BETWEEN join_date AND dateadd(day, 6, join_date) THEN price * 20 
                    ELSE price * 10 
            END
        ) total_points
FROM    cte
GROUP BY customer_id
;
--Bonus Question--

SELECT  s.customer_id
        ,s.order_date
        ,m.product_name
        ,m.price
        ,case    WHEN order_date >= join_date THEN 'Y' 
                 ELSE 'N' 
         END member
FROM    sales s
INNER JOIN menu m
ON      s.product_id = m.product_id
LEFT JOIN members me
-- Ranking
ON      s.customer_id = me.customer_id    WITH cte as ( SELECT s.customer_id, s.order_date, m.product_name, m.price, case WHEN order_date >= join_date THEN 'Y' ELSE 'N' END member FROM sales s INNER JOIN menu m ON s.product_id = m.product_id LEFT JOIN members me ON s.customer_id = me.customer_id )
SELECT  *
        ,case    WHEN member = 'N' THEN NULL 
                 ELSE rank() over(PARTITION BY customer_id, member ORDER BY order_date) 
         END ranking
FROM    cte
;
