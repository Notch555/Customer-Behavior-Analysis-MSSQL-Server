-- 1. What is the total amount each customer spent in the restaurant?
SELECT s.customer_id, SUM (m.price) as total_spent
FROM sales s
JOIN menu m on s.product_id = m.product_id
GROUP BY s.customer_id;
-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM sales s
GROUP BY s.customer_id;
-- 3. What was the first item from the menu purchased by each customer?
WITH customer_first_purchase AS (SELECT s.customer_id, MIN(s.order_date) AS first_puchase_date
FROM sales s
GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_puchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN sales s on cfp.customer_id = s.customer_id
AND cfp.first_puchase_date = s.order_date
INNER JOIN menu m on s.product_id = m.product_id;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT Top 1 m.product_name, COUNT(*) AS total_purchase
FROM sales s
JOIN menu m on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchase DESC;
-- 5. Which item was the most popular for each customer?
WITH customer_popularity AS (
	SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	GROUP BY m.product_name, s.customer_id
)
SELECT cp.customer_id, cp.product_name, cp.purchase_count
FROM customer_popularity cp
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchase_after_membership AS	(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	JOIN members mb ON s.customer_id = mb.customer_id
	WHERE s.order_date  >= mb.join_date
	GROUP BY s.customer_id
	)
SELECT fpam.customer_id, m.product_name
FROM first_purchase_after_membership fpam
JOIN sales s ON s.customer_id = fpam.customer_id
AND fpam.first_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;
-- 7. Which item was purchased just before the customer became a member?
WITH last_purchase_before_membership AS(
	SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
	FROM sales s
	JOIN members mb ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON m.product_id = s.product_id
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(*) AS total_item, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id
JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(
	CASE
		WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
/* 10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, SUM(
	CASE
		WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day,7,mb.join_date)
		THEN m.price*20
		WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.customer_id IN ('A','B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id


--11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= mb.join_date THEN 'Y'
ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

--12. Rank all the things:
