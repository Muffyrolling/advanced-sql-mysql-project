#Product-Level Sales Analysis
#pull monthly trends to date for number of sale, total revenue,and total margin
SELECT 
	YEAR(created_at),
    MONTH(created_at),
    COUNT(order_id),
    SUM(price_usd),
    SUM(price_usd - cogs_usd) AS margin,
    AVG(price_usd)
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1, 2;
#Analyzing Product Launches
#launched 2nd prodcut on jan 6th, pull monthly order volumn, overall conversion rate,revenue per session, and a breakdown of sales by products
#since april 1st 2012  - april 5th 2013
SELECT 
	YEAR(website_sessions.created_at),
    MONTH(website_sessions.created_at),
    COUNT(order_id),
    COUNT(order_id)/COUNT(website_session_id) AS conv_rate,
    SUM(price_usd)/COUNT(website_session_id) AS revenue_per_session,
    COUNT(CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
	COUNT(CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
From website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-01'
GROUP BY 1,2;
#Analyzing Product-Level Website Pathing
#pull clickthrough rates from products since the new product launch on jan 6 2013 by product 
#and compare to the 3 months leading up to launch as a baseline
# filler out products sessions
CREATE TEMPORARY TABLE products_pageview
SELECT 
website_session_id,
website_pageview_id,
CASE 
    WHEN created_at BETWEEN '2012-10-06' AND '2013-01-06' THEN 'pre_products2'
    WHEN created_at BETWEEN '2013-01-06' AND '2013-04-06' THEN 'post_products2'
    ELSE null
    END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN '2012-10-06' AND '2013-04-06'
AND pageview_url = '/products';
SELECT * FROM products_pageview;
# filler out only next page after products page
# 1,AND website_pageviews.website_pageview_id >  pageviewwithtimeperiod.website_pageview_id
#2，	MIN(website_pageviews.website_pageview_id) AS min_pageview,
# filler 之后，只剩下 从products click through 之后的PAGE(要么 fuzzy 要么bear)
CREATE TEMPORARY TABLE sessions_w_nextpage
SELECT 
	time_period,
	products_pageview.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS next_pageview
FROM products_pageview
LEFT JOIN website_pageviews ON products_pageview.website_session_id = website_pageviews.website_session_id
	AND website_pageviews.website_pageview_id >  products_pageview.website_pageview_id
GROUP BY 1, 2;
SELECT * FROM sessions_w_nextpage;
SELECT 
	time_period,
    sessions_w_nextpage.website_session_id,
    pageview_url
FROM sessions_w_nextpage
LEFT JOIN website_pageviews ON sessions_w_nextpage.next_pageview = website_pageviews.website_pageview_id;

SELECT 
	time_period,
    COUNT(sessions_w_nextpage.website_session_id) AS products_sessions,
        COUNT(CASE WHEN pageview_url IS NOT NULL THEN sessions_w_nextpage.website_session_id ELSE NULL END) AS w_nextpage,
        COUNT(CASE WHEN pageview_url IS NOT NULL THEN sessions_w_nextpage.website_session_id ELSE NULL END)/ COUNT(sessions_w_nextpage.website_session_id) AS pct_w_nextpage,
    COUNT(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN sessions_w_nextpage.website_session_id ELSE NULL END) AS mrfuzzy_page,
     COUNT(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN sessions_w_nextpage.website_session_id ELSE NULL END)/ COUNT(sessions_w_nextpage.website_session_id) AS pct_mrfuzzy,
        COUNT(CASE WHEN pageview_url = '/the-forever-love-bear' THEN sessions_w_nextpage.website_session_id ELSE NULL END) AS bear_page,
         COUNT(CASE WHEN pageview_url = '/the-forever-love-bear' THEN sessions_w_nextpage.website_session_id ELSE NULL END)/COUNT(sessions_w_nextpage.website_session_id) AS pct_bear
FROM sessions_w_nextpage
LEFT JOIN website_pageviews ON sessions_w_nextpage.next_pageview = website_pageviews.website_pageview_id
GROUP BY 1;
#Building Product-Level Conversion Funnels
#conversion funnels from each product to conversion
#1 filler out fuzzyandbear_pageview
CREATE TEMPORARY TABLE fuzzyandbearpageview
SELECT 
	CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
		WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
        ELSE NULL
        END AS product_seen,
	website_session_id,
    website_pageview_id,
    pageview_url
FROM website_pageviews
WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');
#2 from fuzzy and bear page , adding next pages url
SELECT 	
	product_seen,
	fuzzyandbearpageview.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url
FROM fuzzyandbearpageview
LEFT JOIN website_pageviews ON fuzzyandbearpageview.website_session_id = website_pageviews.website_session_id
								AND fuzzyandbearpageview.website_pageview_id < website_pageviews.website_pageview_id ;
#flag last query
CREATE TEMPORARY TABLE falgeachpageview
SELECT 	
	product_seen,
	fuzzyandbearpageview.website_session_id,
   COUNT( CASE WHEN website_pageviews.pageview_url = '/cart'THEN 1 ELSE NULL END) AS cart,
      COUNT(  CASE WHEN website_pageviews.pageview_url = '/shipping'THEN 1 ELSE NULL END )AS shipping,
   COUNT( CASE WHEN website_pageviews.pageview_url = '/billing-2'THEN 1 ELSE NULL END )AS billing2,
   COUNT( CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order'THEN 1 ELSE NULL END) AS thankyou
FROM fuzzyandbearpageview
LEFT JOIN website_pageviews ON fuzzyandbearpageview.website_session_id = website_pageviews.website_session_id
								AND fuzzyandbearpageview.website_pageview_id < website_pageviews.website_pageview_id 
GROUP BY 1, 2;
SELECT 
	product_seen,
    COUNT(website_session_id),
    COUNT(CASE WHEN cart = 1 THEN website_session_id ELSE NULL END ) AS to_cart,
        COUNT(CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END ) AS to_shipping,
    COUNT(CASE WHEN billing2 = 1 THEN website_session_id ELSE NULL END ) AS to_billing,
    COUNT(CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END ) AS to_thankyou
FROM falgeachpageview
GROUP BY 1;
#each page click rate
SELECT 
	product_seen,
    COUNT(CASE WHEN cart = 1 THEN website_session_id ELSE NULL END ) /  COUNT(website_session_id)AS productpageclickrate,
        COUNT(CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END ) /    COUNT(CASE WHEN cart = 1 THEN website_session_id ELSE NULL END )AS shippingclickrate,
    COUNT(CASE WHEN billing2 = 1 THEN website_session_id ELSE NULL END ) /  COUNT(CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END )AS billingclickrate,
    COUNT(CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END )/COUNT(CASE WHEN billing2 = 1 THEN website_session_id ELSE NULL END )  AS thankyouclickrate
FROM falgeachpageview
GROUP BY 1;
#Cross-Selling & Product Portfolio Analysis
# on 9/25 we give the customer the option to add a 2nd product on cart page,
#compare the month before vs after the change/ pull ctr form /cart , average products per order,aov. overall revenue per /cart page view.
CREATE TEMPORARY TABLE pageviewwithorder_id
SELECT
	website_pageviews.created_at,
	website_pageviews.website_session_id,
    pageview_url,
    order_id,
    price_usd
FROM website_pageviews
LEFT JOIN orders USING (website_session_id)
WHERE website_pageviews.created_at BETWEEN '2013-08-25' AND '2013-10-25'
		AND pageview_url = '/cart';
SELECT
		CASE WHEN pageviewwithorder_id.created_at BETWEEN '2013-08-25' AND '2013-09-25' THEN 'pre_cross_sell'
    	    WHEN pageviewwithorder_id.created_at BETWEEN '2013-09-25' AND '2013-10-25' THEN 'post_cross_sell'
        ELSE NULL 
        END AS time_period,
COUNT(website_session_id) AS cart_sessions,
COUNT(DISTINCT pageviewwithorder_id.order_id) AS order_sessions,
COUNT(product_id) /COUNT(DISTINCT pageviewwithorder_id.order_id) AS avgproducts_per_order,
SUM(pageviewwithorder_id.price_usd) /COUNT(website_session_id)AS revenue_per_cart
FROM pageviewwithorder_id
LEFT JOIN order_items USING(order_id)
GROUP BY 1;
#ASSIGNMENT: Product Portfolio Expansion
# 12/12 launched a new product called birthday bear,compare the month before vs after session to order conv rate, aov-average order value, product per order
SELECT 
CASE WHEN website_sessions.created_at BETWEEN '2013-11-12' AND '2013-12-12' THEN 'pre_birthdaybear'
    	    WHEN website_sessions.created_at BETWEEN '2013-12-12' AND '2014-01-12' THEN 'post_birthdaybear'
            ELSE NULL
            END AS time_period,
COUNT(website_sessions.website_session_id) AS sessions,
COUNT(order_id) AS orders,
COUNT(order_id) /COUNT(website_sessions.website_session_id) AS sessiontoorder_conv_rate,
SUM(price_usd) /COUNT(order_id) AS aov,
SUM(items_purchased)/COUNT(order_id) 
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;
#Analyzing Product Refund Rates
# 9/13 correct mr fuzzy's qualilty, bear's arm fall off on 08 09/13 and replace with new on 9/16/14
#pull monthly product refund rate by products
SELECT
	YEAR(order_items.created_at),
    	Month(order_items.created_at),
	COUNT(CASE WHEN product_id = 1 THEN order_item_id ELSE NULL END ) AS p1_orders,
    	COUNT(CASE WHEN product_id = 1 THEN order_item_refund_id ELSE NULL END ) /COUNT(CASE WHEN product_id = 1 THEN order_item_id ELSE NULL END ) AS p1_refund_rt,
    	COUNT(CASE WHEN product_id = 2 THEN order_item_id ELSE NULL END ) AS p2_orders,
        COUNT(CASE WHEN product_id = 2 THEN order_item_refund_id ELSE NULL END )/COUNT(CASE WHEN product_id = 2 THEN order_item_id ELSE NULL END )AS p2_refund_r,
	COUNT(CASE WHEN product_id = 3 THEN order_item_id ELSE NULL END ) AS p3_orders,
    COUNT(CASE WHEN product_id = 3 THEN order_item_refund_id ELSE NULL END )/COUNT(CASE WHEN product_id = 3 THEN order_item_id ELSE NULL END )AS p3_refund_r,
	COUNT(CASE WHEN product_id = 4 THEN order_item_id ELSE NULL END ) AS p4_orders,
    COUNT(CASE WHEN product_id = 4 THEN order_item_refund_id ELSE NULL END )/COUNT(CASE WHEN product_id = 4 THEN order_item_id ELSE NULL END )AS p4_refund_r

FROM order_items
LEFT JOIN order_item_refunds USING(order_item_id)
WHERE order_items.created_at <'2014-10-01'
GROUP BY 1,2;

