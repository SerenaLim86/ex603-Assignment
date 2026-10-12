/*
Task 3.3: Hand the team a corrected query with three equivalent forms

Question: Which passengers were involved in disputed bookings?
Find passenger IDs on bookings whose booking status is 'disputed' and return those passengers' details.
*/

-- Form 1: subquery with IN
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

-- Form 2: Common Table Expression using WITH
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

-- Form 3: using EXISTS
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

-- Verify the 3 forms results match using EXCEPT 
-- Returns no rows when all three results are identical
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
One input condition under which the three would not be equivalent:
(NULLs, duplicates, and empty result sets are the usual places equivalence breaks)

These three forms return the same passenger rows & counts currently. All the attributes we use for filter here do 
not have inequivalence result, but if the data are updated to NULLs, duplicates, and empty result, this can change.
For example, if passenger name are repeated or if the insert criteria is updated.
Another probability is if we used attributed like bookings.cancellation_reason as selection criteria. 
However, this will not make sense to be use in this question.
*/
