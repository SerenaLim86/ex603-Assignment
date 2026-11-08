--Task 5.2 — LEFT, RIGHT, and FULL OUTER joins, plus NOT EXISTS and EXCEPT.
-- Mapping: producer = flights, event = bookings


/* ============================================================
   Task 5.2: Find Records That Joins May Exclude

   Part A: Compare INNER JOIN and LEFT JOIN
   Write two queries to compare the results of an inner join and a left
   join. Use LEFT JOIN to return all flights, including those
   who have never had an booking. Write an equivalent query using
   INNER JOIN. Compare the results and determine how many flights are
   excluded by the inner join. Explain which producers are missing and why.
   ============================================================ */

-- LEFT JOIN: all flights including those with no bookings
SELECT f.flight_id, f.flight_number, f.origin_country,
       COUNT(b.booking_id) AS booking_count
FROM flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number, f.origin_country
ORDER BY f.flight_id;

/* Result: 15 rows, one per flight. Flights #14 (VN214) and #15 (VN215) show
   booking_count = 0; the other 13 flights have between 6 and 21 bookings. */


-- INNER JOIN: only flights that have at least one booking 
SELECT f.flight_id, f.flight_number, f.origin_country,
       COUNT(b.booking_id) AS booking_count
FROM flights f
INNER JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number, f.origin_country
ORDER BY f.flight_id;

--Result: 13 rows. Flights #14 and #15 do not appear. 


-- Count of producers excluded by the inner join
   -- flight_id is used for counting, so flights with many bookings are counted
SELECT
    (SELECT COUNT(DISTINCT flight_id) FROM flights) AS left_join_flights,
    COUNT(DISTINCT f.flight_id)                     AS inner_join_flights,
    (SELECT COUNT(DISTINCT flight_id) FROM flights)
      - COUNT(DISTINCT f.flight_id)                 AS excluded_by_inner_join
FROM flights f
INNER JOIN bookings b ON b.flight_id = f.flight_id;


-- Which producers are missing and why
SELECT f.flight_id, f.flight_number, f.origin_country, f.seat_capacity, f.is_active
FROM flights f
LEFT JOIN bookings b ON b.flight_id = f.flight_id
WHERE b.booking_id IS NULL;

/* 
   The inner join excludes 2 of the 15 flights, #14 (VN214, Vietnam)
   and #15 (VN215, Thailand). An inner join keeps a flight only when a
   matching row exists in bookings. These two flights have no bookings so they drop out of the result.
   Both are active flights with real seat capacity (303 and 132), and
   neither has any flight_routes rows either. They look like flights that
   never sold or loaded with bookings, not cancelled flights. Any report built on the inner join (for example the
   Unit 4 average fare per flight) would silently overstate how many flights
   are performing and never show these two. The LEFT JOIN keeps them visible with a booking count of 0.
*/


/* ============================================================
   Part B: Explore RIGHT JOIN and FULL OUTER JOIN
   Write a RIGHT JOIN that returns the same records as the LEFT JOIN from
   Part A. Compare the results to confirm that they match. Write a FULL
   OUTER JOIN that includes matching and unmatched records from both
   tables. Explain what a full outer join can reveal that a left join or
   right join alone may not show. Verify the results rather than assuming
   the queries are equivalent.
   ============================================================ */

-- RIGHT JOIN: the same records as the LEFT JOIN from Part A
   -- Tables are swapped (bookings on the left, flights on the right)
SELECT f.flight_id, f.flight_number, f.origin_country,
       COUNT(b.booking_id) AS booking_count
FROM bookings b
RIGHT JOIN flights f ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number, f.origin_country
ORDER BY f.flight_id;

/* Result: 15 rows, with #14 (VN214) and #15 (VN215) at booking_count = 0. */


-- Verification that the LEFT JOIN and RIGHT JOIN results match
WITH l AS (
  SELECT f.flight_id, f.flight_number, f.origin_country, COUNT(b.booking_id) AS bc
  FROM flights f LEFT JOIN bookings b ON b.flight_id = f.flight_id
  GROUP BY f.flight_id, f.flight_number, f.origin_country),
r AS (
  SELECT f.flight_id, f.flight_number, f.origin_country, COUNT(b.booking_id) AS bc
  FROM bookings b RIGHT JOIN flights f ON b.flight_id = f.flight_id
  GROUP BY f.flight_id, f.flight_number, f.origin_country)
SELECT (SELECT COUNT(*) FROM l) AS left_rows,
       (SELECT COUNT(*) FROM r) AS right_rows,
       (SELECT COUNT(*) FROM (SELECT * FROM l EXCEPT SELECT * FROM r) x) AS in_left_not_right,
       (SELECT COUNT(*) FROM (SELECT * FROM r EXCEPT SELECT * FROM l) y) AS in_right_not_left;

-- Both queries return 15 rows, identical results


-- FULL OUTER JOIN: matching and unmatched records from both tables
SELECT COUNT(*) AS total_rows,
       COUNT(*) FILTER (WHERE f.flight_id IS NOT NULL
                          AND b.booking_id IS NOT NULL) AS matched,
       COUNT(*) FILTER (WHERE b.booking_id IS NULL)     AS flights_without_bookings,
       COUNT(*) FILTER (WHERE f.flight_id IS NULL)      AS bookings_without_flights
FROM flights f
FULL OUTER JOIN bookings b ON b.flight_id = f.flight_id;

/* The 202 rows are the 200 matched booking rows, plus the 2 flights (#14 and
   #15) with no bookings. No booking is missing a flight.

   What a full outer join can reveal that a left or right join alone may not
   show?
   A LEFT JOIN from flights shows only flights with no bookings, and a RIGHT
   JOIN from flights is the same thing written the other way. Neither one
   checks the opposite direction. A FULL OUTER JOIN keeps unmatched rows from
   both tables in one result, so one query answers both questions:
   - Flights with no bookings: 2 (#14 and #15).
   - Bookings with no flight (orphaned bookings): 0.

   The zero orphaned bookings confirms the foreign key is fk_bookings_prod, 
   and all 200 bookings belong to a real flight, the 2 empty flights are 
   the only gap between the tables. If the data had orphaned bookings, a left/right 
   join from flights would have hidden, and the full
   outer join would have shown them with a NULL flight. It makes the full
   outer join a good reconciliation check between two tables.
*/


/* ============================================================
   Part C: Find Producers with No Events Using Two Approaches
   Write two queries that identify producers who have never had an event
   and compare them.
     - NOT EXISTS
     - EXCEPT
   Run both queries and compare their results. In one or two sentences,
   explain how the approaches differ and confirm whether they identify the
   same producers.
   ============================================================ */

-- Approach 1: NOT EXISTS
   --Keeps each flight for which no matching booking row exists: flight_id 14 & 15
SELECT f.flight_id, f.flight_number, f.origin_country
FROM flights f
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.flight_id = f.flight_id
)
ORDER BY f.flight_id;



-- Approach 2: EXCEPT
   -- All flight ids, minus the flight ids that appear in bookings： flight_id 14 & 15
SELECT flight_id
FROM flights
EXCEPT
SELECT flight_id
FROM bookings
ORDER BY flight_id;




-- Comparison approach 1 & 2 as 0 flights
SELECT
    (SELECT COUNT(*) FROM (
        SELECT f.flight_id FROM flights f
        WHERE NOT EXISTS (SELECT 1 FROM bookings b WHERE b.flight_id = f.flight_id)
        EXCEPT
        (SELECT flight_id FROM flights EXCEPT SELECT flight_id FROM bookings)
    ) x) AS in_not_exists_only,
    (SELECT COUNT(*) FROM (
        (SELECT flight_id FROM flights EXCEPT SELECT flight_id FROM bookings)
        EXCEPT
        SELECT f.flight_id FROM flights f
        WHERE NOT EXISTS (SELECT 1 FROM bookings b WHERE b.flight_id = f.flight_id)
    ) y) AS in_except_only;

/* 
   NOT EXISTS checks each flight row and tests whether a matching booking
   exists, so it can return any flights columns, while EXCEPT compares two
   lists of flight ids as sets, so it returns only the id column (and
   removes duplicates). Both approaches identify the same 2 producers,
   flights #14 (VN214) and #15 (VN215), which also match the flights
   excluded by the inner join in Task 5.2 Part A.
*/
