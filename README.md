**Add your Unit 4 queries to the query catalogue, with the business question each answers.**

## Task 4.1 
>#1 Count, total, average, minimum, and maximum of your Paw Air flight across the bookings. 
```
SELECT
    COUNT(fare_paid)            AS count_fare,
    SUM(fare_paid)              AS total_fare,
    ROUND(AVG(fare_paid), 2)    AS avg_fare, --rounded 2 decimal due to long result
    MIN(fare_paid)              AS min_fare,
    MAX(fare_paid)              AS max_fare,
    COUNT(DISTINCT passenger_id) AS distinct_passenger
FROM bookings;
```

>Min_fare indicated 0.00, reflects data quality issue.
```
SELECT booking_status, COUNT(*)
FROM bookings
WHERE fare_paid = 0
GROUP BY booking_status;
```

>#2 - Booking count and average metric for each flights. 
- LEFT join sql show flights also with 0 or NULL booking (JOINT ver in q4_1.sql)
- Additional analysis SQL not included, plase reference in q4_1.sql
```
SELECT
    f.flight_id, f.seat_capacity, f.origin_country,
    COUNT(b.booking_id) AS booking_count,
    ROUND(AVG(b.fare_paid), 2) AS avg_fare
From flights f
LEFT JOIN bookings b on b.flight_id = f.flight_id
GROUP BY f.flight_id
ORDER BY booking_count DESC;
```

>#3 - Which flights have enough volume for their rate to mean anything? 
```
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
```

>#4 - How does the picture change along two dimensions at once? Leadership also wants to understand how performance varies across regions.
```
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
```

#### Summary: How performance vary across producers? 
- By region producer, flights origined from East Asia has more confirmed booking than SE Asia. However, avg fare for SE Asia confirmed booking are little more. More cancelled bookings shown on East Asia originated flights. 
- From booking status analysis, flight #3 will need investigation on why dispute amount is highest. flight# 11, 15 need investigation of possible cancellation of route due to high cancellation and low booking rate. This will remove flights with hgh failure rate.
- Avg fare is around 17-27 for all on or above 16 bookings flights, but the fare amount did not seems to impact the flight impact the booking count. 
*/


## Task 4.2 — conditional aggregation, ROLLUP, and the pipeline. 

>Part A: Two numbers in one pass 
>>For each producer, compute the total number of events and the total number of events classified as failures, in a single pass over the event table, without a WHERE clause filtering the whole query. The outliers here are the producers you will name in your finding.
- ✓  CASE used inside an aggregate — for example SUM(CASE WHEN ... THEN 1 ELSE 0 END) or COUNT(CASE WHEN ... END).
- ✓  Both totals appearing as separate columns in one result set.

```
SELECT
    booking_status,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN fare_paid = 0 THEN 1 ELSE 0 END) AS zero_fare_bookings
FROM bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;
```



>Part B: Subtotals and a grand total
>>The regional director wants subtotals per region and a platform grand total, not the detail rows. Write a query that produces regional subtotals and a platform-wide grand total without including the individual detail rows.
- ✓  GROUP BY ROLLUP (...), or GROUPING SETS or CUBE.
- ✓  A written note identifying which rows are the subtotals and which is the grand total.

```
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
```


>Part C: A two-step pipeline
>>Leadership wants to establish a baseline for evaluating high-volume producers. That needs two steps: use a WITH clause to create an intermediate result that summarizes performance for each producer, then use a second aggregation or filter on that intermediate result to calculate a baseline for high-volume producers.
    - ✓  A WITH clause producing an intermediate aggregate.
    - ✓  A second aggregation or filter applied to that intermediate result.

- Avg fare and zero_fare paid for high-volume flights with booking_count >= 16
- Additional analysis SQL not included, plase reference in q4_2.sql

```
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
```

- With second aggregation

```
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
```