--Task 4.2 — conditional aggregation, ROLLUP, and the pipeline. 

/* Part A: Two numbers in one pass
- compute the total number of booking for each flight 
- total number of booking that classified as failures (bookings with fare 0.00)
use SUM(CASE WHEN ... THEN 1 ELSE 0 END) or COUNT(CASE WHEN ... END)
The outliers here are the producers you will name in your finding. */

--For Part A, state the two questions your conditional aggregation answers side by side.
    --total booking and total booking with fare 0.00 
    --use SUM(CASE WHEN) instead of COUNT(CASE WHEN) so zero-fare paid are included
        --result shows as expected, only cancelled booking has zero-fare (total 34 counts). 
SELECT
    booking_status,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings
FROM bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;


/* Part B: Subtotals and a grand total
The regional director wants subtotals per region and a platform grand total, not the detail rows. Write a query that produces regional subtotals and a platform-wide grand total without including the individual detail rows.
- GROUP BY ROLLUP (...), or GROUPING SETS or CUBE.
 */

--Zero-fare paid regional subtotals across East Asia & SE Asia and a platform-wide grand total without individual detail rows
    --COALESCE replaces NULL when region is 'Other', but should not apply since all regions is in Asia
    --Result Row 1 is All regions grand total (= East + SE Asia)
    --Result Row 2 (East Asia) & 3 (SE Asia) are subtotal.
    --East asia have significantly more zero-fare bookings than SE Asia flights

--Name the reader who needs subtotals rather than detail rows, and say what decision the grand total supports that the group rows do not.
    --reader will be each regional director who manage E Asia and SE Asia flight routes. Grand total provide estimate on how much subtotal cover from all the flights. As a result, East Asia have significantly more zero-fare bookings than SE Asia flights

WITH booking_regions AS (
    SELECT
        b.fare_paid,
        CASE
            WHEN f.origin_country IN ('Japan', 'Korea') THEN 'East Asia'
            WHEN f.origin_country IN ('Singapore', 'Thailand', 'Vietnam') THEN 'Southeast Asia'
            ELSE 'Other'
        END AS region
    FROM bookings b
    JOIN flights f ON f.flight_id = b.flight_id
)
SELECT
    COALESCE(region, 'All regions') AS region,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings
FROM booking_regions
GROUP BY GROUPING SETS ((region), ()) --sub-region, grand total
ORDER BY region;



/* Part C: A two-step pipeline
Leadership wants to establish a baseline for evaluating high-volume producers. That needs two steps: use a WITH clause to create an intermediate result that summarizes performance for each producer, then use a second aggregation or filter on that intermediate result to calculate a baseline for high-volume producers.

--WITH clause to create an intermediate result that summarizes performance for each flights
--second aggregation or filter on that intermediate result to calculate a baseline for high-volume flights.*/

--Avg fare and zero_fare paid for high-volume flights with booking_count >= 16
    --total 8 flights with booking_count >= 16 baseline (as median of all flights fare)
WITH flight_summary AS (
    SELECT
        f.flight_id,
        f.flight_number,
        COUNT(b.booking_id) AS booking_count,
        SUM(CASE WHEN b.fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings,
        ROUND(AVG(b.fare_paid) FILTER (WHERE b.booking_status <> 'cancelled'), 2) AS avg_fare
    FROM flights f
    JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id, f.flight_number
)
SELECT
    flight_id,
    flight_number,
    booking_count,
    zero_fare_bookings,
    ROUND(zero_fare_bookings * 1.0 / booking_count, 2) AS zero_fare_share,
    avg_fare
FROM flight_summary
WHERE booking_count >= 16
ORDER BY zero_fare_share DESC;
--This results show flight#11 has highest zero_fare_share, matches above observation and it also happen to have the lowest avg fare.  Indicate zero fare could lower the avg fare amount.

--Note: Added second aggregation
    --avg_flight_zero_fare_share is the compute avg of zero-paid fare to total booking count on each flight for the 8 total flights
    --baseline_avg_fare only calculate the avg 8 flights fare
WITH flight_summary AS (
    SELECT
        f.flight_id,
        COUNT(b.booking_id) AS booking_count,
        SUM(CASE WHEN b.fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings,
        ROUND(AVG(b.fare_paid) FILTER (WHERE b.booking_status <> 'cancelled'), 2) AS avg_fare
    FROM flights f
    JOIN bookings b ON b.flight_id = f.flight_id
    GROUP BY f.flight_id
)
SELECT
    COUNT(*) AS high_volume_flights,
    ROUND(AVG(zero_fare_bookings * 1.0 / booking_count), 2) AS avg_zero_fare_share,
    ROUND(AVG(avg_fare), 2) AS avg_fare
FROM flight_summary
WHERE booking_count >= 16;


--Additional analysis: each of the flight's zero-fare (baseline) share tells flight#4 has zero fare share of 33% will need closer look 
SELECT
    f.flight_id,
    f.flight_number,
    COUNT(b.booking_id) AS booking_count,
    SUM(CASE WHEN b.fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings,
    ROUND(SUM(CASE WHEN b.fare_paid = 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(b.booking_id), 2) AS zero_fare_share
FROM flights f
JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number
ORDER BY zero_fare_share DESC;
