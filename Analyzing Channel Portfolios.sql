#Analyzing Channel Portfolios

#expanded channel portfolios // 8/22 launched second paid search channel bsearch
SELECT 
	YEARWEEK(created_at),
    MIN(DATE(created_at)),
    COUNT(CASE WHEN utm_source = 'gsearch'THEN website_session_id ELSE NULL END) AS gsearch_sessions,
        COUNT(CASE WHEN utm_source = 'bsearch'THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-29" AND utm_campaign ='nonbrand'
GROUP BY 1;
#Comparing Channel Characteristics
#for bsearch nonbrand,pull the percentage of traffic coming on mobile, compare that to the gsearch 08/22- 11/30
SELECT 
	utm_source,
    COUNT(website_session_id) AS sessions,
    COUNT(CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END ) AS mobile_sessions,
    COUNT(CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END )/COUNT(website_session_id) AS pct_mobile
FROM website_sessions
WHERE created_at BETWEEN "2012-08-22" AND "2012-11-29" 
	-- AND utm_source IN ('gsearch', 'bsearch')
    AND utm_campaign ='nonbrand' 
    GROUP BY 1;
#Cross-Channel Bid Optimization
# nonbrand conversion rate from sessions to orders for gsearch and bsearch and slice the data by device type.  8/22-9/19
SELECT
	device_type,
	utm_source,
	COUNT(website_session_id) AS sessions,
    	COUNT(order_id) AS orders,
COUNT(order_id) /COUNT(website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at BETWEEN "2012-08-22" AND "2012-09-19" 
    AND utm_campaign ='nonbrand' 
GROUP BY 1,2
ORDER BY device_type;
#Analyzing Channel Portfolio Trends
#pull weekly session volumn for gsearch and bsearch, nonbrand, break down device, since 11/4 /// 11/4-12/22
 SELECT 
	-- YEARWEEK(created_at),
    MIN(DATE(created_at)),
    			COUNT(CASE WHEN utm_source ='bsearch'AND device_type='desktop' THEN website_session_id ELSE NULL END ) AS b_desk_sessions,
        COUNT(CASE WHEN utm_source ='gsearch'AND device_type='desktop' THEN website_session_id ELSE NULL END ) AS g_desk_sessions,
        COUNT(CASE WHEN utm_source ='bsearch'AND device_type='desktop' THEN website_session_id ELSE NULL END )/ COUNT(CASE WHEN utm_source ='gsearch'AND device_type='desktop' THEN website_session_id ELSE NULL END )  AS pct_btog_desk,
		        COUNT(CASE WHEN utm_source ='bsearch'AND device_type='mobile' THEN website_session_id ELSE NULL END ) AS b_mob_sessions,
		        COUNT(CASE WHEN utm_source ='gsearch'AND device_type='mobile' THEN website_session_id ELSE NULL END ) AS g_mob_sessions,
COUNT(CASE WHEN utm_source ='bsearch'AND device_type='mobile' THEN website_session_id ELSE NULL END )/ COUNT(CASE WHEN utm_source ='gsearch'AND device_type='mobile' THEN website_session_id ELSE NULL END ) AS pct_btog_mob
FROM website_sessions
 WHERE created_at BETWEEN "2012-11-04" AND "2012-12-22" 
    AND utm_campaign ='nonbrand' 
GROUP BY YEARWEEK(created_at) ;
#Analyzing Direct, Brand-Driven Traffic
#when utm source is null http refer is null --- called direct traffic-customer type in the company website in the browse
#when utm source is null http refer is not null ----called organic search-customer search company name in google
SELECT
	YEAR(created_at),
	MONTH(created_at),
            COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organice_search,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_typein,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) /   COUNT(CASE WHEN utm_campaign = 'nonbrand'  THEN website_session_id ELSE NULL END) AS dirct_pct_of_nonbrand,
     COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(CASE WHEN utm_campaign = 'nonbrand'  THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS paid_brand_search,
    COUNT(CASE WHEN utm_campaign = 'nonbrand'  THEN website_session_id ELSE NULL END) AS paid_nonbrand_search

FROM website_sessions
 WHERE created_at < "2012-12-23" 
 GROUP BY 1,2;
 
 /*SELECT
	CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ' organice_search'
    WHEN utm_source IS NULL AND http_referer IS NULL THEN ' direct_typein'
    WHEN utm_campaign = 'brand' THEN ' paid_brand_search'
    WHEN utm_campaign = 'nonbrand'  THEN ' paid_nonbrand_search'
    ELSE 'other '
    END AS channel_group,
    COUNT(website_session_id)

FROM website_sessions
 WHERE created_at < "2012-12-23" 
GROUP BY 1 */
