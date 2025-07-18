/* 1 show volume growth/ pull overall sessions and order volume trended by quarter for the life of the business -- 2015/3/20*/
SELECT
	YEAR(website_sessions.created_at),
    QUARTER(website_sessions.created_at),
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
GROUP BY 1,2
ORDER BY 1,2 ;
/*2 show quarterly figures since we launched, for session to order conversion rate,
revenue per order, revenue per session*/
SELECT
	YEAR(website_sessions.created_at),
    QUARTER(website_sessions.created_at),
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
     COUNT(DISTINCT order_id) /COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_rate,
     SUM(price_usd)/COUNT(DISTINCT order_id) AS revenue_per_order,
	SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
GROUP BY 1,2
ORDER BY 1,2 ;
/*show how we've grown specific channels/ 
#pull a quarterly view of orders from Gsearch non brand, Bsearch nonbrand,
brand search overall, organice search, and direct type_in*/
SELECT
	YEAR(website_sessions.created_at),
    QUARTER(website_sessions.created_at),
        COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS gsearch_nonbrandorders,
        COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS bsearch_nonbrandorders,
    COUNT(CASE WHEN utm_campaign = 'brand'  THEN order_id ELSE NULL END) AS brand_searchorders,
	COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organice_searchorders,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_typeinorders
FROM website_sessions
JOIN orders USING (website_session_id)
GROUP BY 1,2
ORDER BY 1,2;
/*4,show the overall session to order conversion rate trends for those same channels by quarter.
please also make a note of any periods where we made major improvements or optimizations*/
SELECT
	YEAR(website_sessions.created_at),
    QUARTER(website_sessions.created_at),
COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END)/  COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rate,
        COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) / COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rate,
    COUNT(CASE WHEN utm_campaign = 'brand'  THEN order_id ELSE NULL END)/ COUNT(CASE WHEN utm_campaign = 'brand'  THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rate,
	COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) / COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organice_search_conv_rate,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) / COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_typein_conv_rate
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
GROUP BY 1,2
ORDER BY 1,2;
/*5.pull monthly trending for revenue and margin by product,
along with total sales and revenue.*/
SELECT
	YEAR(created_at),
    MONTH(created_at),
	SUM(CASE WHEN product_id =1 THEN price_usd ELSE NULL END) AS p1_revenue,
    	SUM(CASE WHEN product_id =1 THEN price_usd - cogs_usd ELSE NULL END) AS p1_margin,
    	SUM(CASE WHEN product_id =2 THEN price_usd ELSE NULL END) AS p2_revenue,
            	SUM(CASE WHEN product_id =2 THEN price_usd - cogs_usd ELSE NULL END) AS p2_margin,
        	SUM(CASE WHEN product_id =3 THEN price_usd ELSE NULL END) AS p3_revenue,
                    	SUM(CASE WHEN product_id =3 THEN price_usd - cogs_usd  ELSE NULL END) AS p3_margin,
                    	SUM(CASE WHEN product_id =3 THEN price_usd ELSE NULL END) AS p3_revenue,
                                            	SUM(CASE WHEN product_id =3 THEN price_usd - cogs_usd  ELSE NULL END) AS p3_margin,
            	SUM(CASE WHEN product_id =4 THEN price_usd ELSE NULL END) AS p4_revenue,
                            	SUM(CASE WHEN product_id =4 THEN price_usd - cogs_usd  ELSE NULL END) AS p4_margin,
                                SUM(price_usd) AS total_revenue,
									SUM(price_usd - cogs_usd ) AS total_margin

FROM order_items
GROUP BY 1,2 
ORDER BY 1,2;
/*6. pull monthly sessions to the /products page, 
and show how teh % of those sessions clicking through another page 
has changed over time, along with a view of how conversion from /products
to placing an order has improved*/
CREATE TEMPORARY TABLE products_with_next_pageviews
SELECT 
	sessionswith_products.created_at,
	sessionswith_products.website_session_id,
    products_pageview,
    MIN(website_pageviews.website_pageview_id) AS next_pageview
FROM 
(
SELECT
	website_pageviews.created_at,
	website_session_id,
    website_pageview_id AS products_pageview,
    pageview_url
FROM website_pageviews
WHERE pageview_url = '/products'
) AS sessionswith_products
LEFT JOIN website_pageviews ON sessionswith_products.website_session_id = website_pageviews.website_session_id
							AND website_pageviews.website_pageview_id > sessionswith_products.products_pageview
GROUP BY 1,2,3;
SELECT 
	products_with_next_pageviews.created_at,
	products_with_next_pageviews.website_session_id,
    products_pageview,
    next_pageview,
    order_id
FROM products_with_next_pageviews
LEFT JOIN orders USING (website_session_id);
#summrazing from last query
SELECT 
	YEAR(products_with_next_pageviews.created_at) AS yr,
    	MONTH(products_with_next_pageviews.created_at) AS mo,
	COUNT(products_pageview) AS products_page_sessions,
    COUNT(next_pageview) AS next_page_sessions,
    COUNT(next_pageview) /COUNT(products_pageview) AS products_clickthro_rate,
    COUNT(order_id) AS orders,
    COUNT(order_id)/COUNT(products_pageview) AS products_sessionto_orders_rate
FROM products_with_next_pageviews
LEFT JOIN orders USING (website_session_id)
GROUP BY 1,2
ORDER BY 1,2;
/*7.  4th product was available as a primary product on 2014-12-05,
(it was previously only a cross-sell item),pull sales data since then,
and show how well each product cross_sells from one another*/
CREATE TEMPORARY TABLE primarywith_Xsoldproducts
SELECT
	primary_products.order_id,
	primary_product_id,
    product_id AS x_sold_products
FROM (
SELECT
	primary_product_id,
    order_id
FROM orders
WHERE orders.created_at > '2014-12-05'
) AS primary_products
LEFT JOIN order_items ON primary_products.order_id = order_items.order_id
	AND is_primary_item = 0 ;-- only bring the corss sell
SELECT 
	primary_product_id,
    COUNT(order_id) AS total_orders,
    COUNT(CASE WHEN x_sold_products = 1 THEN order_id ELSE NULL END )AS x_sold_p1,
      COUNT(  CASE WHEN x_sold_products = 2 THEN order_id ELSE NULL END) AS x_sold_p2,
   COUNT( CASE WHEN x_sold_products = 3 THEN order_id ELSE NULL END )AS x_sold_p3,
   COUNT( CASE WHEN x_sold_products = 4 THEN order_id ELSE NULL END )AS x_sold_p4
FROM 
primarywith_Xsoldproducts
GROUP BY 1
ORDER BY 1;

