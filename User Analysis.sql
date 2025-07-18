#Analyzing Repeat Visit & Purchase Behavior
#pull data on how many website vistors come back for another session, 2014-01-01 2014-11-01
CREATE TEMPORARY TABLE sessions_withrepeats
SELECT
	new_sessions.user_id,
    new_session_id,
    website_sessions.website_session_id AS repeated_sessions
FROM (
SELECT
	user_id,
    website_session_id AS new_session_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
	AND is_repeat_session = 0
) AS new_sessions
LEFT JOIN website_sessions ON new_sessions.user_id = website_sessions.user_id
		AND created_at BETWEEN '2014-01-01' AND '2014-11-01'
	AND is_repeat_session = 1;
SELECT*FROM sessions_withrepeats;
SELECT
	count_repeatsessions,
    COUNT(user_id)
FROM(
SELECT
	user_id,
    COUNT(repeated_sessions) AS count_repeatsessions
FROM sessions_withrepeats
GROUP BY 1
) AS count_repeatsessions
GROUP BY 1
ORDER BY count_repeatsessions;
# pull min max and average time between first and second session for cutomer who do come back
CREATE TEMPORARY TABLE newsessions
SELECT
	created_at AS first_date,
    user_id,
    website_session_id
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND is_repeat_session = 0;

CREATE TEMPORARY TABLE repeatsessions
SELECT
	user_id,
    MIN(ws1.website_session_id) AS repeatedsession
FROM website_sessions ws1
WHERE ws1.created_at BETWEEN '2014-01-01' AND '2014-11-03'
	AND ws1.is_repeat_session = 1
GROUP BY 1;
CREATE TEMPORARY TABLE repeatedsessionwith_time
SELECT 
	created_at AS 2nd_date,
	repeatsessions.user_id,
    repeatedsession
FROM repeatsessions 
LEFT JOIN website_sessions ON repeatsessions.repeatedsession = website_sessions.website_session_id;
SELECT
	first_date,
    newsessions.user_id,
    newsessions.website_session_id,
    repeatedsessionwith_time.2nd_date,
    repeatedsessionwith_time.repeatedsession
FROM newsessions
LEFT JOIN repeatedsessionwith_time ON newsessions.user_id =  repeatedsessionwith_time.user_id;

SELECT

    AVG(DATEDIFF(2nd_date, first_date) )AS avg_days_firstto2nd,
    MIN(DATEDIFF(2nd_date, first_date)) AS min_days_firstto2nd,
    MAX(DATEDIFF(2nd_date, first_date))AS max_days_firstto2nd

FROM newsessions
LEFT JOIN repeatedsessionwith_time ON newsessions.user_id =  repeatedsessionwith_time.user_id;
 #Analyzing Repeat Channel Behavior
 #conparing new vs repeat sessions by channel
 SELECT
	CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN' organice_search'
     WHEN utm_campaign = 'brand' THEN 'paid_brand_search'
     WHEN utm_source IS NULL AND http_referer IS NULL THEN ' direct_typein'
  WHEN utm_campaign = 'nonbrand'  THEN 'paid_nonbrand_search'
    WHEN utm_source = 'socialbook'  THEN 'paidsocial'

  ELSE NULL
  END AS channel_group,
  COUNT(CASE WHEN is_repeat_session = 0 Then website_session_id ELSE NULL END)AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 Then website_session_id ELSE NULL END)AS repeat_sessions
 FROM website_sessions
 WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
 GROUP BY 1
 ORDER BY repeat_sessions DESC;
 #Analyzing New & Repeat Conversion Rates
#do a comparison of coversion rate and revenue per session for repeat sessions vs new sessions
SELECT
	is_repeat_session,
    COUNT(website_sessions.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
     COUNT(order_id) / COUNT(website_sessions.website_session_id) AS session_order_conv_rate,
     SUM(price_usd)/COUNT(website_sessions.website_session_id) AS revenue_per_session
 FROM website_sessions
 LEFT JOIN orders USING(website_session_id)
 WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08'
 GROUP BY 1;
 
 


     

