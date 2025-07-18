#Mid-course project
# growth story over first 8 month
/*
1.	Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 
SELECT 
	YEAR(website_sessions.created_at)AS yr,
    MONTH(website_sessions.created_at)AS mo,
    COUNT(DISTINCT website_session_id) AS gsearch_sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE utm_source="gsearch" AND website_sessions.created_at < "2012-11-27"
GROUP BY 1,2;
/*SELECT*
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE utm_source="gsearch" AND website_sessions.created_at < "2012-11-27";*/
/*
2.	Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/ 
SELECT 
	YEAR(website_sessions.created_at)AS yr,
    MONTH(website_sessions.created_at)AS mo,
    COUNT(CASE WHEN utm_campaign= "nonbrand" THEN website_sessions.website_session_id ELSE NULL END ) AS gsearch_nonbrandsessions,
        COUNT(CASE WHEN utm_campaign= "brand" THEN website_sessions.website_session_id ELSE NULL END ) AS gsearch_brandsessions,
	COUNT(CASE WHEN utm_campaign= "nonbrand" THEN order_id ELSE NULL END ) AS gsearch_nonbrandorders,
        COUNT(CASE WHEN utm_campaign= "brand" THEN order_id ELSE NULL END ) AS gsearch_brandsessionsorders
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE utm_source="gsearch" AND website_sessions.created_at < "2012-11-27"
GROUP BY 1,2;
/*
3.	While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/ 
SELECT 
	YEAR(website_sessions.created_at)AS yr,
    MONTH(website_sessions.created_at)AS mo,
    COUNT(CASE WHEN device_type= "desktop" THEN website_sessions.website_session_id ELSE NULL END ) AS gsearch_desktopsessions,
        COUNT(CASE WHEN device_type= "mobile" THEN website_sessions.website_session_id ELSE NULL END ) AS gsearch_mobsessions,
	 COUNT(CASE WHEN device_type= "desktop" THEN order_id ELSE NULL END ) AS gsearch_desktoporders,
        COUNT(CASE WHEN device_type= "mobile" THEN order_id ELSE NULL END ) AS gsearch_moborders
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE utm_source="gsearch" AND utm_campaign = 'nonbrand' AND website_sessions.created_at < "2012-11-27"
GROUP BY 1,2;
/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 
*/ 
# session to order conversion rate by month over first 8month
#list relevant column
SELECT 
	website_pageviews.created_at,
    website_pageviews.website_session_id,
    order_id
FROM website_pageviews
LEFT JOIN orders USING (website_session_id)
WHERE website_pageviews.created_at < "2012-11-27" AND pageview_url IN ('/lander-1','/home');
#summarazing 
SELECT 
	YEAR(website_pageviews.created_at) AS yr,
    MONTH(	website_pageviews.created_at)AS mo,
	COUNT(DISTINCT website_pageviews.website_session_id)AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) /COUNT(DISTINCT website_pageviews.website_session_id) AS sessionto_order_conv_rate
FROM website_pageviews
LEFT JOIN orders USING (website_session_id)
WHERE website_pageviews.created_at < "2012-11-27" AND pageview_url IN ('/lander-1','/home')
GROUP BY 1,2;
/*
6.	For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use 
nonbrand sessions and revenue since then to calculate incremental value)
*/ 
# estimate revenue that lander1 test earn us(begain at 06/19 - test ends at7/28)
#find first view page id when lander1 first launched
SELECT 
	MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1';
# min pageview_id = 23504 from last query, now find gsearch nonbrand session id left join pageviews,test end on 07/28
CREATE TEMPORARY TABLE landing_page
SELECT 
	website_sessions.website_session_id,
    MIN(website_pageview_id) AS min_pageview
FROM website_sessions
LEFT JOIN website_pageviews USING (website_session_id)
WHERE 
	website_pageview_id >= 23504
	AND website_sessions.created_at < '2012-07-28'
    AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    GROUP BY 1;
SELECT * FROM landing_page;
#join website pageview
CREATE TEMPORARY TABLE sessions_withlandingpage
SELECT landing_page.website_session_id,
pageview_url
FROM landing_page
LEFT JOIN website_pageviews ON landing_page.min_pageview = website_pageviews.website_pageview_id;
# left join orders,
SELECT website_session_id,
pageview_url,
order_id
FROM sessions_withlandingpage
LEFT JOIN orders USING (website_session_id)
WHERE pageview_url IN ('/home','/lander-1');
#summarzing
SELECT 
pageview_url,
COUNT(website_session_id),
COUNT(order_id),
COUNT(order_id)/COUNT(website_session_id)
FROM sessions_withlandingpage
LEFT JOIN orders USING (website_session_id)
WHERE pageview_url IN ('/home','/lander-1')
GROUP BY 1;
/*
7.	For the landing page test you analyzed previously, it would be great to show a full conversion funnel 
from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/ 
#full conversion funnel from each of the two pages to order(begain at 06/19 - test ends at7/28)
#list gsearch nonbrand sessions with pageview url
CREATE TEMPORARY TABLE sessionswithpageview
SELECT 
	website_sessions.website_session_id,
    website_pageview_id,
    pageview_url
FROM website_sessions
LEFT JOIN website_pageviews USING (website_session_id)
WHERE 
	website_pageview_id >= 23504
	AND website_sessions.created_at < '2012-07-28'
    AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand';
    SELECT * FROM sessionswithpageview;
#falg each page
SELECT website_session_id,
	CASE WHEN pageview_url = "/lander-1" THEN 1 ELSE 0 END AS "lander_1",
    	CASE WHEN pageview_url = "/home" THEN 1 ELSE 0 END AS "home",
	CASE WHEN pageview_url = "/products" THEN 1 ELSE 0 END AS "products" ,
	CASE WHEN pageview_url = "/the-original-mr-fuzzy" THEN 1 ELSE 0 END AS 'mr_fuzzy',
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS 'cart',
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS 'shipping',
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS 'billing',
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS 'thankyou'
FROM sessionswithpageview;
# group it by website-session id
CREATE TEMPORARY TABLE eachsession_flagged
SELECT website_session_id,
	MAX(CASE WHEN pageview_url = "/lander-1" THEN 1 ELSE 0 END) AS "lander_1",
    	MAX(CASE WHEN pageview_url = "/home" THEN 1 ELSE 0 END) AS "home",
	MAX(CASE WHEN pageview_url = "/products" THEN 1 ELSE 0 END) AS "products" ,
	MAX(CASE WHEN pageview_url = "/the-original-mr-fuzzy" THEN 1 ELSE 0 END) AS 'mr_fuzzy',
	MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END )AS 'cart',
	MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS 'shipping',
	MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END )AS 'billing',
   MAX( CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END )AS 'thankyou'
FROM sessionswithpageview
GROUP BY 1;
SELECT * FROM eachsession_flagged;
SELECT
	CASE WHEN lander_1 = 1 THEN "saw lander page"
		WHEN home = 1 THEN "saw home page"
        ELSE NULL 
        END AS which_firstpage_saw,
	COUNT(website_session_id) AS firstpage_sessions,
	COUNT(CASE WHEN products = 1 THEN website_session_id ELSE NULL END )AS "products",
  	COUNT(CASE WHEN mr_fuzzy = 1 THEN website_session_id ELSE NULL END )AS "mr_fuzzy",
	COUNT(CASE WHEN cart = 1 THEN website_session_id ELSE NULL END )AS "cart",
	COUNT(CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END )AS "shipping",
	COUNT(CASE WHEN billing = 1 THEN website_session_id ELSE NULL END )AS "billing",
	COUNT(CASE WHEN thankyou = 1 THEN website_session_id ELSE NULL END )AS "thankyou"
FROM eachsession_flagged
GROUP BY 1;
/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 
#quantity the impact of billing test and revenue per billing page session
# find when billing 2 first launched sep 10th
SELECT pageview_url,min(created_at)
FROM website_pageviews WHERE pageview_url = '/billing-2';
SELECT 
	pageview_url,
    COUNT(website_session_id),
    COUNT(order_id),
    SUM(price_usd)/COUNT(website_session_id) AS revenue_per_billing_seen
    FROM (
SELECT 
	website_session_id,
    pageview_url,
    order_id,
    price_usd
FROM website_sessions
LEFT JOIN website_pageviews USING (website_session_id)
LEFT JOIN orders USING (website_session_id)
WHERE 
	website_sessions.created_at BETWEEN "2012-09-10" AND "2012-11-10"
    AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND pageview_url IN ('/billing-2', '/billing')
    ) AS session_pageview_order
GROUP BY 1; # lift $8 billing 2 compare to billing per billing page seen
#past month
SELECT 
	COUNT(website_session_id)
FROM website_pageviews
WHERE pageview_url IN ('/billing-2', '/billing') AND created_at BETWEEN "2012-10-27" AND "2012-11-27" -- past month
# 1193 biling page viewed in last month, lift :&8 per billing page view
