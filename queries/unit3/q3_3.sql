/*
Task 3.3: Hand the team a corrected query- the three equivalent forms

Question: Which passengers were involved in disputed bookings?
Step 1- Find passenger IDs on bookings whose status is 'disputed'.
Step 2- Return those passengers' details.
*/

-- Form 1: IN with a subquery.
SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_country
FROM passengers AS p
WHERE p.passenger_id IN (
    SELECT b.passenger_id
    FROM bookings AS b
    WHERE b.booking_status = 'disputed'
)
ORDER BY p.passenger_id;

-- Form 2: CTE followed by IN.
WITH disputed_passengers AS (
    SELECT b.passenger_id
    FROM bookings AS b
    WHERE b.booking_status = 'disputed'
)
SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_country
FROM passengers AS p
WHERE p.passenger_id IN (
    SELECT passenger_id
    FROM disputed_passengers
)
ORDER BY p.passenger_id;

-- Form 3: correlated EXISTS.
SELECT
    p.passenger_id,
    p.passenger_name,
    p.home_country
FROM passengers AS p
WHERE EXISTS (
    SELECT 1
    FROM bookings AS b
    WHERE b.passenger_id = p.passenger_id
      AND b.booking_status = 'disputed'
)
ORDER BY p.passenger_id;

-- Verify that the result rows match, not just the row counts.
-- This returns no rows when all three results are identical.
WITH
in_form AS (
    SELECT p.passenger_id, p.passenger_name, p.home_country
    FROM passengers AS p
    WHERE p.passenger_id IN (
        SELECT b.passenger_id
        FROM bookings AS b
        WHERE b.booking_status = 'disputed'
    )
),
cte_form AS (
    WITH disputed_passengers AS (
        SELECT b.passenger_id
        FROM bookings AS b
        WHERE b.booking_status = 'disputed'
    )
    SELECT p.passenger_id, p.passenger_name, p.home_country
    FROM passengers AS p
    WHERE p.passenger_id IN (
        SELECT passenger_id
        FROM disputed_passengers
    )
),
exists_form AS (
    SELECT p.passenger_id, p.passenger_name, p.home_country
    FROM passengers AS p
    WHERE EXISTS (
        SELECT 1
        FROM bookings AS b
        WHERE b.passenger_id = p.passenger_id
          AND b.booking_status = 'disputed'
    )
),
differences AS (
    (SELECT * FROM in_form EXCEPT SELECT * FROM cte_form)
    UNION ALL
    (SELECT * FROM cte_form EXCEPT SELECT * FROM in_form)
    UNION ALL
    (SELECT * FROM in_form EXCEPT SELECT * FROM exists_form)
    UNION ALL
    (SELECT * FROM exists_form EXCEPT SELECT * FROM in_form)
)
SELECT *
FROM differences
ORDER BY passenger_id;

/*
Equivalence condition:
These three positive-membership forms return the same passenger rows here:
passenger_id is NOT NULL and is a primary key in passengers. Duplicate
passenger_id values in bookings do not change membership results.

A related NULL pitfall occurs if using NOT IN for a negative-membership
version: if its subquery returns even one NULL, NOT IN evaluates to UNKNOWN
for comparisons and can return no rows. NOT EXISTS does not have that issue.
*/
