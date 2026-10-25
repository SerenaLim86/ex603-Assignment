--Task 4.1 — the baseline, per-producer, HAVING, and two-dimension queries

/* #1 - Count, total, average, minimum, and maximum of your Paw Air flight across the bookings.
-how many distinct actors appear?
Review your results carefully. For example, if your metric should never be zero but your minimum value is zero, 
this may indicate another data-quality issue that needs investigation.*/

--Event table (bookings) metrics, relationship between fare paid and each distinct passenger who booked a flight  
SELECT
    COUNT(fare_paid)            AS count_fare,
    SUM(fare_paid)              AS total_fare,
    ROUND(AVG(fare_paid), 2)    AS avg_fare, --rounded 2 decimal due to long result
    MIN(fare_paid)              AS min_fare,
    MAX(fare_paid)              AS max_fare,
    COUNT(DISTINCT passenger_id) AS distinct_passenger
FROM bookings;

--Min_fare indicated 0.00, because constrain allows (fare_paid >= 0), reflects data quality issue. (later query indicates 0.00 fare paid are cancellation flight fare)
SELECT booking_status, COUNT(*)
FROM bookings
WHERE fare_paid = 0
GROUP BY booking_status;


/* #2 - Booking count and average metric for each flights. 
Sort the results from the flights from most to least bookings flights
Consider what these results tell you about differences in activity and performance across flights.*/

--Join only show flights that have booking, not counting 0 or NULL
--japan top booked origin country, avg fare are similar and booking count in smaller and larger flights almost the same indicating larger planes with higher seat capacity are not needed. 

SELECT
    f.flight_id, f.seat_capacity, f.origin_country,
    COUNT(b.booking_id) AS booking_count,
    ROUND(AVG(b.fare_paid), 2) AS avg_fare
From flights f
JOIN bookings b on b.flight_id = f.flight_id
GROUP BY f.flight_id
ORDER BY booking_count DESC;

--Comparing LEFT join show flights also with 0 or NULL booking
SELECT
    f.flight_id, f.seat_capacity, f.origin_country,
    COUNT(b.booking_id) AS booking_count,
    ROUND(AVG(b.fare_paid), 2) AS avg_fare
From flights f
LEFT JOIN bookings b on b.flight_id = f.flight_id
GROUP BY f.flight_id
ORDER BY booking_count DESC;

--Additional analysis on each flights booking status count (canceled, confirmed, dispute) below:
SELECT
    f.flight_id,
    f.seat_capacity,
    f.origin_country,
    COUNT(b.booking_id) AS booking_count,
    COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'confirmed') AS confirmed_count,
    COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'disputed')  AS disputed_count,
    COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'cancelled') AS cancelled_count,
    ROUND(AVG(b.fare_paid) FILTER (WHERE b.booking_status <> 'cancelled'), 2) AS avg_fare
FROM flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.seat_capacity, f.origin_country
ORDER BY confirmed_count DESC;

--Pick the MIN booking confirmation and MAX booking dispute flight to determine which flight might be root cause of previous frozen pay out 
-- Max Dispute bookings shows flight #3 from Korea has 2 dispute
WITH flight_summary AS (
    SELECT
        f.flight_id,
        f.flight_number,
        f.origin_country,
        COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'disputed') AS disputed_count
    FROM flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number, f.origin_country
)
SELECT flight_id, flight_number, origin_country, disputed_count
FROM flight_summary
ORDER BY disputed_count DESC
LIMIT 1;

-- Max cancelled bookings flight #11 from Japan has 5 cancellation
WITH flight_summary AS (
    SELECT
        f.flight_id,
        f.flight_number,
        f.origin_country,
        COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'cancelled') AS cancelled_count
    FROM flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number, f.origin_country
)
SELECT flight_id, flight_number, origin_country, cancelled_count
FROM flight_summary
ORDER BY cancelled_count DESC
LIMIT 1;


-- Min confirmed bookings shows flight #15 from Thailand has 0 confirmed booking 
WITH flight_summary AS (
    SELECT
        f.flight_id,
        f.flight_number,
        f.origin_country,
        COUNT(b.booking_id) FILTER (WHERE b.booking_status = 'confirmed') AS confirmed_count
    FROM flights f
    LEFT JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_id, f.flight_number, f.origin_country
)
SELECT flight_id, flight_number, origin_country, confirmed_count
FROM flight_summary
ORDER BY confirmed_count ASC
LIMIT 1;


/* #3 - Which flights have enough volume for their rate to mean anything? 
A flight with only a few booking may have a high failure rate that is not representative of their usual performance. 
    --flight #6 have 21 booking out of 90 capacity, flight #4 have a high failure rate for 6 bookings

Choose a minimum booking-count threshold and use HAVING to include only flights who meet that threshold. Explain why you selected your threshold. */
    --16 is median of booking count across flights so it is good cut off to measure what is on or above. All show Asian countries flights.
    --Removed bookings that are canceled to be count as avg fare since the cancelled flight always have 0.00 fare, can impact the true avg

SELECT
    f.flight_id,
    f.seat_capacity,
    f.origin_country,
    COUNT(b.booking_id) AS booking_count,
    ROUND(AVG(b.fare_paid) FILTER (WHERE b.booking_status <> 'cancelled'), 2) AS avg_fare
FROM flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.seat_capacity, f.origin_country
HAVING COUNT(b.booking_id) >= 16
ORDER BY booking_count DESC;


/* #4 - How does the picture change along two dimensions at once? Leadership also wants to understand how performance varies across regions.

Write a query that groups the data by two dimensions, including region, and calculates the relevant summary statistics. Your results should contain one row for each combination of the two dimensions so that regional leaders can review their results. */

--Compare East Asia and SE Asia peformance on flights booking status (canceled, confirmed, dispute)
    --Note: All avg_fare for cancelled booking are 0.00 because no fare were charged
SELECT
    CASE
        WHEN f.origin_country IN ('Japan', 'Korea') THEN 'East Asia'
        WHEN f.origin_country IN ('Singapore', 'Thailand', 'Vietnam') THEN 'Southeast Asia'
        ELSE 'Other'
    END AS region,
    b.booking_status,
    COUNT(b.booking_id)        AS booking_count,
    ROUND(AVG(b.fare_paid), 2) AS avg_fare
FROM flights f
JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY region, b.booking_status
ORDER BY region, b.booking_status;


/* Summary: How performance vary across producers? 
By region producer, flights origined from East Asia has more confirmed booking than SE Asia. However, avg fare for SE Asia confirmed booking are little more. More cancelled bookings shown on East Asia originated flights. 

From booking status analysis, flight #3 will need investigation on why dispute amount is highest. flight# 11, 15 need investigation of possible cancellation of route due to high cancellation and low booking rate. This will remove flights with hgh failure rate.

Avg fare is around 17-27 for all on or above 16 bookings flights, but the fare amount did not seems to impact the flight impact the booking count. 
*/
