--Task 3.2: Find the bug
--The dashboard query contains two SQL problems. Your goal is to reproduce each problem, show what goes wrong, and then fix it.

-- Part A: 
-- 1. Pick a nullable column on your event or producer table.
-- bookings.cancellation_reason has NULL values already in the supplied dataset, no rows need to be inserted.
SELECT cancellation_reason FROM bookings

--For practice, I also inserted a new row in flights.flights_number as NULL, removed NOT NULL in flights_number attribute under flight table to allow NULL insert
INSERT INTO flights (
    flight_id,
    flight_number,
    first_scheduled_on,
    origin_country,
    tail_number,
    seat_capacity,
    is_active
)
VALUES (
    16,
    NULL,
    '2022-11-05',
    'United States',
    'UQ-1016',
    180,
    TRUE
);

--test new row with flight_number IS NULL
SELECT flight_number FROM flights

--2. query with a negation or inequality predicate on that column
--Returns all bookings not equal to 'Passenger no show' under cancellation_reason, ommitted NULL silently.
SELECT
    booking_id,
    booking_status,
    cancellation_reason
FROM bookings
WHERE cancellation_reason <> 'Passenger no show' 
ORDER BY booking_id ASC;


--Total row count for all bookings not equal to 'Passenger no show' is 22
SELECT COUNT(*) AS total_rows
FROM bookings
WHERE cancellation_reason <> 'Passenger no show';

--3. Total row count of NULL ommited when select cancellation_reason <> 'Passenger no show' is 166:
SELECT COUNT(*) AS rows_omitted_due_to_null
FROM bookings
WHERE cancellation_reason IS NULL;


-- Compare Total Passenger not cancelled vs. Ommitted counts.
-- rows with reason 'Passenger no show' are also excluded intentionally.
SELECT
    COUNT(*) AS total_bookings,
    COUNT(*) FILTER (
        WHERE cancellation_reason <> 'Passenger no show'
    ) AS not_passenger_no_show_reason,
    COUNT(*) FILTER (
        WHERE cancellation_reason IS NULL
    ) AS omitted_null_reason,
    COUNT(*) FILTER (
        WHERE cancellation_reason = 'Passenger no show'
    ) AS passenger_no_show_reason
FROM bookings;
--The total of omitted_null_reason is 166, total_bookings - null omitted_null_reason: 200-166 = 34.
--not_passenger_no_show_reason + passenger_no_show_reason = 22+12 + 34
--Only 34 total rows have a cancellation_reason. 

-- 4.Repair using IS NULL for null reasons.
SELECT
    booking_id,
    booking_status,
    cancellation_reason
FROM bookings
WHERE cancellation_reason <> 'Passenger no show' 
    OR cancellation_reason IS NULL
ORDER BY booking_id ASC;

-- Repair using COALESCE for null reasons.
SELECT
    booking_id,
    booking_status,
    COALESCE(cancellation_reason, 'Missing reason') AS cancellation_reason
FROM bookings
WHERE cancellation_reason <> 'Passenger no show'
   OR cancellation_reason IS NULL
ORDER BY booking_id ASC;

--test by recount total_passenger_canceled = 188
SELECT COUNT(*) AS total_passenger_canceled
FROM bookings
WHERE cancellation_reason <> 'Passenger no show'
   OR cancellation_reason IS NULL;

--Part B: The alias that did not exist yet
--1. defining an alias in SELECT and referencing that alias in WHERE. 
--Capture error message
SELECT
    booking_id,
    fare_paid * fare_multiplier AS adjusted_fare
FROM bookings
WHERE adjusted_fare > 50;

-- Received PostgreSQL error:
--column "adjusted_fare" does not exist
--LINE 5: WHERE discount_fare > 50;

--2a. Rewrite: repeat the expression in WHERE.
SELECT
    booking_id,
    fare_paid * fare_multiplier AS adjusted_fare
FROM bookings
WHERE fare_paid * fare_multiplier > 50
ORDER BY adjusted_fare ASC;

-- 2b. Rewrite: define the alias in a CTE, then filter its column.
WITH booking_fares AS (
    SELECT
        booking_id,
        fare_paid * fare_multiplier AS adjusted_fare
    FROM bookings
)
SELECT
    booking_id,
    adjusted_fare
FROM booking_fares
WHERE adjusted_fare > 50
ORDER BY adjusted_fare ASC;
