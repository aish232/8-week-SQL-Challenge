---##1) What is the total amount each customer spent at the restaurant?

SELECT S.CUSTOMER_ID , SUM(M.PRICE) AS MONEY_SPENT
FROM SALES AS S INNER JOIN MENU AS M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID ;

---##2) How many days has each customer visited the restaurant?

SELECT S.CUSTOMER_ID , COUNT(DISTINCT ORDER_DATE) AS NUMBER_OF_VISITS
FROM SALES AS S 
GROUP BY S.CUSTOMER_ID;

---##3) What was the first item from the menu purchased by each customer?

SELECT DISTINCT CUSTOMER_ID, PRODUCT_NAME
FROM
(
SELECT S.CUSTOMER_ID , M.PRODUCT_NAME , DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE ) AS RNK
FROM SALES AS S INNER JOIN MENU AS M
ON S.PRODUCT_ID = M.PRODUCT_ID
) A WHERE RNK = 1;


---##4) What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT M.PRODUCT_NAME, COUNT(S.PRODUCT_ID) AS COUNT_OF_PURCHASE
FROM SALES AS S INNER JOIN MENU AS M
ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME
ORDER BY COUNT(S.PRODUCT_ID) DESC 
LIMIT 1;


---##5) Which item was the most popular for each customer?

SELECT CUSTOMER_ID , PRODUCT_NAME AS MOST_POPULAR_PRODUCT,PRODUCT_COUNT
FROM 
(
	SELECT CUSTOMER_ID ,PRODUCT_NAME,PRODUCT_COUNT,
	DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY PRODUCT_COUNT DESC) AS RNK
	FROM 
	(
		SELECT S.CUSTOMER_ID ,M.PRODUCT_NAME, COUNT(PRODUCT_NAME) AS PRODUCT_COUNT
		FROM SALES AS S INNER JOIN MENU AS M
		ON S.PRODUCT_ID = M.PRODUCT_ID
        GROUP BY S.CUSTOMER_ID ,M.PRODUCT_NAME
	) A 
) B WHERE RNK = 1;


---##6) Which item was purchased first by the customer after they became a member?

SELECT A.CUSTOMER_ID ,ORDER_DATE, A.PRODUCT_NAME AS FIRST_PURCHASED_PRODUCT
FROM 
(
	SELECT S.CUSTOMER_ID , N.PRODUCT_NAME , S.ORDER_DATE , DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID
    ORDER BY ORDER_DATE ASC) AS RNK
	FROM SALES S INNER JOIN MEMBERS M 
	ON S.CUSTOMER_ID = M.CUSTOMER_ID
	INNER JOIN MENU N
	ON S.PRODUCT_ID = N.PRODUCT_ID
	WHERE S.ORDER_DATE >= M.JOIN_DATE
) A WHERE RNK = 1;


---##7) Which item was purchased just before the customer became a member?

SELECT A.CUSTOMER_ID ,ORDER_DATE, A.PRODUCT_NAME AS FIRST_PURCHASED_PRODUCT
FROM 
(
	SELECT S.CUSTOMER_ID , N.PRODUCT_NAME , S.ORDER_DATE , DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE DESC) AS RNK
	FROM SALES S INNER JOIN MEMBERS M 
	ON S.CUSTOMER_ID = M.CUSTOMER_ID
	INNER JOIN MENU N
	ON S.PRODUCT_ID = N.PRODUCT_ID
	WHERE S.ORDER_DATE < M.JOIN_DATE
) A WHERE RNK = 1;


---##8)What is the total items and amount spent for each member before they became a member?
 
SELECT S.CUSTOMER_ID , COUNT(DISTINCT N.PRODUCT_NAME) AS TOTAL_ITEMS_UNIQUE , SUM(PRICE) AS AMOUNT_SPENT
FROM SALES S INNER JOIN MEMBERS M 
ON S.CUSTOMER_ID = M.CUSTOMER_ID
INNER JOIN MENU N
ON S.PRODUCT_ID = N.PRODUCT_ID
WHERE S.ORDER_DATE < M.JOIN_DATE
GROUP BY S.CUSTOMER_ID ;

---## 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH POINTS_TABLE AS
(
SELECT *, CASE WHEN PRODUCT_NAME = "sushi" THEN price * 20 
          ELSE PRICE * 10
          END AS POINTS
          FROM MENU 
)

SELECT CUSTOMER_ID , SUM(PRODUCT_COUNT*POINTS) AS TOTAL_POINTS
FROM 
(
SELECT S.CUSTOMER_ID,P.PRODUCT_NAME,P.POINTS,COUNT(PRODUCT_NAME) AS PRODUCT_COUNT
FROM SALES S INNER JOIN POINTS_TABLE P
ON S.PRODUCT_ID = P.PRODUCT_ID
GROUP BY S.CUSTOMER_ID,P.PRODUCT_NAME,P.POINTS
) A
GROUP BY CUSTOMER_ID;


---## 10)In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - #how many points do 
#customer A and B have at the end of January?

WITH DATE_TABLE AS 
(
 SELECT *, 
 DATE_ADD(JOIN_DATE,INTERVAL 6 DAY ) AS VALID_DATE, 
 DATE('2021-01-31') AS LAST_DATE
 FROM MEMBERS AS M
)

SELECT D.CUSTOMER_ID,ORDER_DATE,D.JOIN_DATE,VALID_DATE,LAST_DATE,PRODUCT_NAME,PRICE,
SUM(CASE WHEN M.PRODUCT_NAME = "sushi" THEN 2*10*M.PRICE
		 WHEN S.ORDER_DATE BETWEEN D.JOIN_DATE AND D.VALID_DATE THEN 2*10*M.PRICE
         ELSE 10*M.PRICE
         END ) AS POINTS
FROM DATE_TABLE D 
INNER JOIN SALES S
ON D.CUSTOMER_ID = S.CUSTOMER_ID
INNER JOIN MENU M 
ON S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE < D.LAST_DATE
GROUP BY D.CUSTOMER_ID,ORDER_DATE,D.JOIN_DATE,VALID_DATE,LAST_DATE,PRODUCT_NAME,PRICE
ORDER BY D.CUSTOMER_ID;

---##Bonus Question 1
SELECT S.CUSTOMER_ID , S.ORDER_dATE , M.PRODUCT_NAME, M.PRICE,
CASE WHEN ORDER_DATE >= JOIN_DATE THEN 'Y' ELSE 'N'
END AS MEMBER
FROM SALES S LEFT JOIN MENU M 
ON S.PRODUCT_ID = M.PRODUCT_ID
LEFT JOIN MEMBERS B
ON S.CUSTOMER_ID = B.CUSTOMER_ID
ORDER BY CUSTOMER_ID , ORDER_dATE;

---##Bonus Question 2
SELECT * , CASE WHEN MEMBER = 'N' 
		   THEN NULL ELSE
           DENSE_RANK() OVER(PARTITION BY CUSTOMER_ID,MEMBER ORDER BY ORDER_DATE) 
           END AS RANKING
FROM
(
SELECT S.CUSTOMER_ID , S.ORDER_dATE , M.PRODUCT_NAME, M.PRICE,
CASE WHEN ORDER_DATE >= JOIN_DATE THEN 'Y' ELSE 'N' 
END AS MEMBER
FROM SALES S LEFT JOIN MENU M 
ON S.PRODUCT_ID = M.PRODUCT_ID
LEFT JOIN MEMBERS B
ON S.CUSTOMER_ID = B.CUSTOMER_ID
ORDER BY CUSTOMER_ID , ORDER_dATE
) A



