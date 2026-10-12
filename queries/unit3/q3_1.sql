Task 3.1 — all exploration queries, each under a numbered comment header. 


SELECT driver_id, display_name, avg_rating
FROM  drivers
WHERE is_active = TRUE
AND avg_rating >= 4.5
ORDER BY avg_rating DESC
LIMIT 10;

SELECT * FROM airports;
SELECT * FROM flights;

-- 3.1.1 Find Active, highly rated producer- flights. 
-- Requirement: Sort them and return the first ten.
SELECT
    flight_id,
    flight_number,
    origin_country,
    tail_number,
    seat_capacity,
    is_active
FROM flights
WHERE is_active = TRUE
ORDER BY flight_id ASC
LIMIT 10;

-- 3.1.2 Find all possible event statuses. 
-- Requirement: Display the distinct values in the event status column. 
--Look carefully at the results. Are there more statuses than you expected? 

SELECT DISTINCT booking_status
FROM bookings
ORDER BY booking_status;
--booking_status has no defined value, one can insert anything VARCHAR(20) and NOT NULL

SELECT DISTINCT is_active
FROM flights
ORDER BY is_active;

SELECT DISTINCT is_active
FROM passengers
ORDER BY is_active;

-- 3.1.3 Filter the events in two different ways. 
-- Requirement: one query that filters a numeric range for booking fare_paid
SELECT
    booking_id,
    flight_id,
    fare_paid
FROM bookings
WHERE fare_paid BETWEEN 10.00 AND 20.00
ORDER BY fare_paid ASC;

-- Requirement: one query that filters booking_status using an explicit list of values ('confirmed', 'cancelled') with IN 
SELECT
    booking_id,
    flight_id,
    booking_status
FROM bookings
WHERE booking_status IN ('confirmed', 'cancelled')
ORDER BY booking_status, booking_id;

-- 3.1.4 Work with text and missing values. 
-- Requirement: find producers names match a text pattern using LIKE (Notes: No value is NULL and LIKE, so I separeted requirements)
SELECT
    flight_id,
    flight_number,
    origin_country,
    seat_capacity
FROM flights
WHERE flight_number LIKE 'VN2%'
ORDER BY flight_number;

-- Requirement: Identify records where a reason is (NULL). Use COALESCE to replace a NULL cancellation_reason to Missing reason
SELECT
    booking_id,
    booking_status,
    cancellation_reason,
    COALESCE(cancellation_reason, 'Missing reason') AS reason_label
FROM bookings
WHERE cancellation_reason IS NULL
ORDER BY booking_id;


-- 3.1.5 Make the results easier to understand. Create a query with calculated/computed columns that would make sense to someone who does not work with SQL. Depending on your theme, you might calculate or label:
-- Requirement: 
--     a payout amount,
--     a time of day,
--     a value/rating category,
--     or another useful business measure.
-- Use CASE where appropriate to create plain-language categories.

--Extracted bags weight category for airport baggage fee/ labour required & hours to categorize Morning, Afternoon, Evening
SELECT
    booking_id,
    flight_id,
    bags_kg,
    CASE
        WHEN bags_kg < 11 THEN 'Regular'
        WHEN bags_kg > 10 and bags_kg < 25 THEN 'Heavy'
        ELSE 'Overweight'
    END AS bags_weight,
    CASE
        WHEN EXTRACT(HOUR FROM booked_at) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM booked_at) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM booked_at) BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS booking_time
FROM bookings
ORDER BY bags_kg ASC, booked_at ASC, booking_id;