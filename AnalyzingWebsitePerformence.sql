#Finding Top Website Pages
SELECT
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY COUNT(website_pageview_id) DESC;

#Finding Top Entry Pages
CREATE TEMPORARY TABLE entry_page
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_view_page
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;
SELECT* FROM entry_page;
SELECT 
	pageview_url,
	COUNT(ep.first_view_page) AS first_page
FROM entry_page ep
JOIN website_pageviews wp ON ep.first_view_page = wp.website_pageview_id
GROUP BY pageview_url;

#Analyzing Bounce Rates & Landing Page Tests
#Calculating Bounce Rates
	#1,find the first page view sessions 2, filler out the bounced sessions
CREATE TEMPORARY TABLE sessions_and_firstpage 
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_page_id
FROM website_pageviews
WHERE created_at <"2012-06-14"
GROUP BY 1;
CREATE TEMPORARY TABLE bounced_firstpage
SELECT 
	sf.website_session_id,
    COUNT(website_pageview_id) AS bounced_count
FROM sessions_and_firstpage sf
LEFT JOIN website_pageviews USING (website_session_id)
GROUP BY 1
HAVING bounced_count =1;

SELECT 
	bf.website_session_id AS bounced_fistpage,
    wp.website_session_id AS firstpage
FROM website_pageviews wp
LEFT JOIN bounced_firstpage bf USING (website_session_id);
SELECT 
  COUNT(bf.website_session_id) AS bounced_sessions,
  COUNT(sf.website_session_id) AS sessions,
  COUNT(bf.website_session_id)/ COUNT(sf.website_session_id) AS bounced_rate
FROM sessions_and_firstpage sf
LEFT JOIN bounced_firstpage bf USING (website_session_id);

#Analyzing Landing Page Tests
# 1,findwhen the new landing page launched 2, finding the first website_pageview_id 3,identifying the landing page for each sessions
#4, counting pageviews for each session, to identify bounced 5, summarizing
SELECT
	pageview_url,
    MIN(created_at)
FROM website_pageviews
WHERE created_at < "2012-07-28" 
GROUP BY 1;
CREATE TEMPORARY TABLE landing_testpage
SELECT 
	wp.website_session_id,
    MIN(website_pageview_id) AS min_pageview
FROM website_pageviews wp
JOIN website_sessions ws USING (website_session_id)
WHERE wp.created_at BETWEEN '2012-06-19' AND  "2012-07-28"
				AND utm_source = 'gsearch'
                AND utm_campaign = "nonbrand"
GROUP BY 1;
CREATE TEMPORARY TABLE landing_pagewithurl
SELECT 
	landing_testpage.website_session_id,
    min_pageview,
    pageview_url
FROM landing_testpage
JOIN website_pageviews wp ON landing_testpage.min_pageview = wp.website_pageview_id;
-- SELECT* FROM landing_pagewithurl
  CREATE TEMPORARY TABLE bounced_sessionv2  
 SELECT 
	landing_pagewithurl.website_session_id,
    landing_pagewithurl.pageview_url,
    COUNT(website_pageview_id) AS bounced_count
FROM   landing_pagewithurl
LEFT JOIN website_pageviews USING(website_session_id)
WHERE created_at BETWEEN '2012-06-19' AND  "2012-07-28"
GROUP BY 1,2
HAVING COUNT(website_pageview_id) = 1;
SELECT * FROM bounced_sessionv2;
/*SELECT 
	lp.website_session_id AS landingpagesession,
    bp.website_session_id AS bouncedpagesession,
    lp.pageview_url AS landingurl,
    bp.pageview_url AS bouncedurl
    
FROM landing_pagewithurl lp
LEFT JOIN bounced_sessionv2 bp USING (website_session_id)
	*/
SELECT 
	landing_pagewithurl.pageview_url,
    COUNT( DISTINCT landing_pagewithurl.website_session_id) AS sessions,
      COUNT(DISTINCT bounced_sessionv2.website_session_id) AS bounced_sessions,
     COUNT(bounced_sessionv2.website_session_id)/COUNT(landing_pagewithurl.website_session_id) AS bounced_rate
FROM landing_pagewithurl
LEFT JOIN bounced_sessionv2 USING (website_session_id)
GROUP BY 1;
# Landing Page Trend Analysis
# 1, fillter out gsearch and nonbrand web sessions 2, find volume of home and lander weekly 3, find bounced session for each 
CREATE TEMPORARY TABLE landing_pagev3withpagecount
SELECT 
	wp.website_session_id,
    MIN(website_pageview_id) AS min_pageview,
    COUNT(website_pageview_id) AS pagecount
FROM website_pageviews wp
LEFT JOIN website_sessions USING (website_session_id)
WHERE wp.created_at BETWEEN "2012-06-01" AND "2012-08-31"
	AND utm_source = 'gsearch'
	AND utm_campaign = "nonbrand"
    GROUP BY 1;
SELECT * FROM landing_pagev3withpagecount;
# adding pageview_url and created_at/ list all the relevent column
SELECT
	landing_pagev3withpagecount.website_session_id,
    landing_pagev3withpagecount.min_pageview,
    landing_pagev3withpagecount.pagecount,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = "/home" THEN pageview_url ELSE NULL END AS home_sessions,
	CASE WHEN pageview_url = '/lander-1' THEN pageview_url ELSE NULL END AS lander_sessions,
    CASE WHEN pagecount = 1 Then pagecount ELSE NULL END AS bounced_page
FROM landing_pagev3withpagecount 
LEFT JOIN website_pageviews ON landing_pagev3withpagecount.min_pageview = website_pageviews.website_pageview_id;
#summarzing by week(bounce rate, home sessions, lander sessions)
SELECT
	-- YEARWEEK(created_at),
    MIN(DATE(created_at)),
	COUNT(CASE WHEN pageview_url = "/home" THEN pageview_url ELSE NULL END )AS home_sessions,
	COUNT(CASE WHEN pageview_url = '/lander-1' THEN pageview_url ELSE NULL END )AS lander_sessions,
	COUNT(CASE WHEN pagecount = 1 Then pagecount ELSE NULL END) AS bounced_sessions,
    COUNT(landing_pagev3withpagecount.website_session_id) AS total_sessions,
   COUNT(CASE WHEN pagecount = 1 Then pagecount ELSE NULL END)/ COUNT(landing_pagev3withpagecount.website_session_id) AS bounce_rate
FROM landing_pagev3withpagecount 
LEFT JOIN website_pageviews ON landing_pagev3withpagecount.min_pageview = website_pageviews.website_pageview_id
GROUP BY YEARWEEK(created_at);
#Building Conversion Funnels & Testing Conversion Paths
#Building Conversion Funnels
#1,flag each url 2, finding each session_madeit 3, summrazing
CREATE TEMPORARY TABLE flagsessions
SELECT
	website_session_id,
    website_pageview_id,
    pageview_url,
    CASE WHEN pageview_url = "/lander-1" THEN 1 ELSE 0 END AS "lander_1",
	CASE WHEN pageview_url = "/products" THEN 1 ELSE 0 END AS "products" ,
	CASE WHEN pageview_url = "/the-original-mr-fuzzy" THEN 1 ELSE 0 END AS 'mr_fuzzy',
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS 'cart',
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS 'shipping',
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS 'billing',
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS 'thankyou'
FROM
(SELECT website_session_id,
    website_pageview_id,
    pageview_url
FROM website_pageviews
JOIN website_sessions USING (website_session_id)
WHERE utm_source = 'gsearch'
	AND website_sessions.created_at BETWEEN "2012-08-5" AND "2012-09-05") AS gsearchsession;
SELECT * FROM flagsessions;
CREATE TEMPORARY TABLE page_made_it
SELECT 
	website_session_id,
	MAX(lander_1) AS first_land,
    MAX(products)AS procusts_madeit,
	MAX(mr_fuzzy) AS mr_fuzzy_madeit,
	MAX(cart) AS cart_madeit,
	MAX(shipping) AS shipping_madeit,
	MAX( billing) AS billing_madeit,
    MAX(thankyou) AS thankyou_madeit
FROM flagsessions
GROUP BY 1;
SELECT
 COUNT(CASE WHEN first_land = 1 THEN 1 ELSE NULL END )AS "first_land",
 COUNT(CASE WHEN procusts_madeit = 1 THEN 1 ELSE NULL END) AS "procusts_madeit",
 COUNT(CASE WHEN mr_fuzzy_madeit = 1 THEN 1 ELSE NULL END )AS "mr_fuzzy_madeit",
COUNT( CASE WHEN cart_madeit = 1 THEN 1 ELSE NULL END )AS "cart_madeit",
COUNT( CASE WHEN shipping_madeit = 1 THEN 1 ELSE NULL END )AS "shipping_madeit",
 COUNT(CASE WHEN billing_madeit = 1 THEN 1 ELSE NULL END )AS "billing_madeit",
 COUNT( CASE WHEN thankyou_madeit = 1 THEN 1 ELSE NULL END )AS "thankyou_madeit"
FROM page_made_it;
#calculate conversion rate 
SELECT 
COUNT(CASE WHEN procusts_madeit = 1 THEN 1 ELSE NULL END)/COUNT(CASE WHEN first_land = 1 THEN 1 ELSE NULL END )AS firstland_click_through,
COUNT(CASE WHEN mr_fuzzy_madeit = 1 THEN 1 ELSE NULL END )/COUNT(CASE WHEN procusts_madeit = 1 THEN 1 ELSE NULL END) AS products_click_through,
COUNT( CASE WHEN cart_madeit = 1 THEN 1 ELSE NULL END )/COUNT(CASE WHEN mr_fuzzy_madeit = 1 THEN 1 ELSE NULL END ) AS cart_click_through,
COUNT( CASE WHEN shipping_madeit = 1 THEN 1 ELSE NULL END )/COUNT( CASE WHEN cart_madeit = 1 THEN 1 ELSE NULL END ) AS shipping_click_through,
COUNT(CASE WHEN thankyou_madeit = 1 THEN 1 ELSE NULL END )/COUNT( CASE WHEN billing_madeit = 1 THEN 1 ELSE NULL END )AS billing_click_through
FROM page_made_it;
# Analyzing Conversion Funnel Tests
#1,finding when billing2 launched 
SELECT 
	pageview_url,
    MIN(created_at)
FROM website_pageviews
WHERE created_at < "2012-11-10" AND pageview_url = '/billing-2'
GROUP BY 1;
#find billing billing2 and left join orders
SELECT 
	  pageview_url,
    website_pageviews.website_session_id,
    order_id
FROM website_pageviews
LEFT JOIN orders USING (website_session_id)
WHERE website_pageviews.created_at BETWEEN "2012-09-10" AND "2012-11-10"
AND pageview_url IN ('/billing-2','/billing' );
# use above query as subquery
SELECT
pageview_url,
COUNT(website_session_id) AS sessions,
COUNT(order_id) AS orders,
COUNT(order_id)/COUNT(website_session_id) AS billtoorder_rate
FROM (SELECT 
	  pageview_url,
    website_pageviews.website_session_id,
    order_id
FROM website_pageviews
LEFT JOIN orders USING (website_session_id)
WHERE website_pageviews.created_at BETWEEN "2012-09-10" AND "2012-11-10"
AND pageview_url IN ('/billing-2','/billing' ) )AS billingswith_orders
GROUP BY 1
ORDER BY pageview_url;