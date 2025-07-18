# Finding Top Traffic Sources
SELECT utm_source,
		utm_campaign,
        http_referer,
        COUNT(website_session_id) AS sessions
FROM website_sessions 
WHERE created_at < "2012-04-12"
GROUP BY utm_source,
		utm_campaign,
        http_referer;
        
#Traffic Source Conversion Rates
SELECT utm_source,
		utm_campaign,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT order_id) AS orders,
       COUNT(DISTINCT order_id)/ COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions ws
LEFT JOIN orders USING (website_session_id)
WHERE ws.created_at < "2012-04-14"
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
    
#Bid Optimization & Trend Analysis
#Traffic Source Trending 
SELECT 
	YEAR (created_at),
	WEEK(created_at),
    MIN(DATE(created_at)) AS week_started_at,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1,2;

# Bid Optimization for Paid Traffic
SELECT
	device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT( DISTINCT order_id) AS orders,
    COUNT( DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM website_sessions ws
LEFT JOIN orders USING (website_session_id)
WHERE 
	 ws.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1 with ROLLUP;

#Trending w/ Granular Segments
SELECT
	-- YEAR(ws.created_at),
    -- WEEK(ws.created_at),
	MIN(DATE(ws.created_at)) AS week_started_at,
   COUNT( CASE WHEN device_type = "desktop" THEN website_session_id ELSE NULL END) AS dtop_sessions,
      COUNT( CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END) AS mob_sessions,
      COUNT(CASE WHEN device_type = "desktop" THEN order_id ELSE NULL END) AS dtop_orders,
     COUNT(CASE WHEN device_type = "mobile" THEN order_id ELSE NULL END) AS mob_orders
FROM website_sessions ws
	LEFT JOIN orders USING (website_session_id)
WHERE 
ws.created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(ws.created_at),
    WEEK(ws.created_at)

   





