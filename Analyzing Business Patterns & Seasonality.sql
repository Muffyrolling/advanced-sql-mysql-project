# Analyzing Business Patterns & Seasonality
#weekday 0-monday 1 tuesday etc..
#Analyzing Seasonality
#by month
SELECT
	    YEAR(website_sessions.created_at),
	MONTH(website_sessions.created_at),
    COUNT(DISTINCT website_sessions.website_session_id),
    COUNT(DISTINCT order_id)
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at BETWEEN '2012-01-01' AND '2012-12-31'
GROUP BY 1,2;
#by week
SELECT
	    -- YEARWEEK(website_sessions.created_at),
     MIN(DATE(website_sessions.created_at)),
    COUNT(website_sessions.website_session_id),
    COUNT(order_id)
FROM website_sessions
LEFT JOIN orders USING (website_session_id)
WHERE website_sessions.created_at BETWEEN '2012-01-01' AND '2012-12-31'
GROUP BY YEARWEEK(website_sessions.created_at);
#Analyzing Business Patterns
#weekday 0-monday 1 tuesday etc..
SELECT
	HOUR(created_at),
    COUNT(CASE WHEN clean_weekday = 'mon'THEN website_session_id ELSE NULL END) AS mon,
        COUNT(CASE WHEN clean_weekday = 'tue'THEN website_session_id ELSE NULL END) AS tue,
    COUNT(CASE WHEN clean_weekday = 'wed'THEN website_session_id ELSE NULL END) AS wed,
    COUNT(CASE WHEN clean_weekday = 'thur'THEN website_session_id ELSE NULL END) AS thur,
    COUNT(CASE WHEN clean_weekday = 'fri'THEN website_session_id ELSE NULL END) AS fri,
    COUNT(CASE WHEN clean_weekday = 'sat'THEN website_session_id ELSE NULL END) AS sat,
        COUNT(CASE WHEN clean_weekday = 'sun'THEN website_session_id ELSE NULL END) AS sun
FROM (
SELECT 
	created_at,
    website_session_id,
    CASE 
		WHEN WEEKDAY(created_at) = 0 THEN 'mon'
        		WHEN WEEKDAY(created_at) = 1 THEN 'tue'
		WHEN WEEKDAY(created_at) = 2 THEN 'wed'
		WHEN WEEKDAY(created_at) = 3 THEN 'thur'
		WHEN WEEKDAY(created_at) = 4 THEN 'fri'
		WHEN WEEKDAY(created_at) = 5 THEN 'sat'
		WHEN WEEKDAY(created_at) = 6 THEN 'sun'
	ELSE null
    END AS clean_weekday
FROM website_sessions
WHERE website_sessions.created_at BETWEEN '2012-09-15' AND '2012-11-15'
) AS sessionwithweekday
GROUP BY 1
ORDER BY 1




