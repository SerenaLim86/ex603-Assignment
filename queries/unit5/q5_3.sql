--Task 5.3 — the CROSS JOIN and the EXPLAIN statement.
-- Mapping: producer = flights, event = bookings, catalog = airports


/* ============================================================
   Part A: Explore CROSS JOIN
    Write a CROSS JOIN between two small tables.
    Then:
    1.Count the rows in each source table.
    2.Run the CROSS JOIN and count the resulting rows.
    3.Show how the result matches the multiplication of the two source table counts.
    4. Explain when a Cartesian product might be useful and when it could indicate a query error.
    For example, if one table has 5 rows and another has 4 rows, the cross join produces 20 rows.

    Choose small tables so the result is manageable.
   ============================================================ */

-- 1: count the rows in each source table
SELECT 'flights'  AS source_table, COUNT(*) AS row_count FROM flights
UNION ALL
SELECT 'airports' AS source_table, COUNT(*) AS row_count FROM airports;

/* Analysis: flights has 15 rows and airports has 5 rows All 15 flights uses 5 airports. */


--  2: run the CROSS JOIN (first 10 of the resulting rows)
SELECT f.flight_id, f.flight_number, a.airport_id, a.iata_code
FROM flights f
CROSS JOIN airports a
ORDER BY f.flight_id, a.airport_id
LIMIT 10;

/* Every flight is paired with every airport. For example, flight 1
   (VN201) appears 5 times, once with each of SGN, HAN, SIN, NRT and ICN,
   and then the same 5 pairs repeat for flight 2 (VN202). */


-- 3: count the CROSS JOIN rows and compare with the multiplication
SELECT
    (SELECT COUNT(*) FROM flights)                       AS flights_rows,
    (SELECT COUNT(*) FROM airports)                      AS airports_rows,
    (SELECT COUNT(*) FROM flights CROSS JOIN airports)   AS cross_join_rows,
    (SELECT COUNT(*) FROM flights)
      * (SELECT COUNT(*) FROM airports)                  AS flights_x_airports;

/* 
   The CROSS JOIN returns 75 rows, which matches 15 flights x 5 airports = 75.
   There is no join condition, so every row of flights is paired with every
   row of airports.

   4.When a Cartesian product is useful:
   - To list every possible combination, for example every flight and
     airport pair, to find routes that could be added. Of the 75 pairs, 25
     exist in flight_routes, so 50 are not yet routes.

   When it could indicate a query error:
   - When it happens by accident, for example a missing or wrong ON
     condition, or a comma-separated FROM list with no WHERE condition. The
     row count multiplies. Joining bookings (200 rows) to passengers
     (30 rows) this way would return 6,000 rows of mostly meaningless
     pairs. A result much larger than either table is the warning sign.
*/

/* ============================================================
   Part B: Examine a Query Execution Plan
   Return to your three-table join from Task 5.1, Part A. Use PostgreSQL's
   EXPLAIN command to examine how the database plans to execute the query.
   ============================================================ */

-- EXPLAIN Task 5.1 3 tables JOINT query: shows the planned execution without running the query
EXPLAIN
SELECT p.passenger_id, p.passenger_name, f.flight_id, f.flight_number,
       b.booking_id, b.booked_at, b.booking_status, b.fare_paid
FROM bookings b
JOIN passengers p ON p.passenger_id = b.passenger_id
JOIN flights f ON f.flight_id = b.flight_id
ORDER BY b.booked_at;


-- EXPLAIN ANALYZE also runs the query and reports actual timings.
EXPLAIN ANALYZE
SELECT p.passenger_id, p.passenger_name, f.flight_id, f.flight_number,
       b.booking_id, b.booked_at, b.booking_status, b.fare_paid
FROM bookings b
JOIN passengers p ON p.passenger_id = b.passenger_id
JOIN flights    f ON f.flight_id    = b.flight_id
ORDER BY b.booked_at;

/* 
   Query plan:
   - bookings and passengers are both read with a Seq Scan and joined with a
     Hash Join on passenger_id. The planner builds a hash table from
     passengers (30 rows) and probes it with each of the 200 bookings.
     With tables this small, a full scan is cheaper than using an index.
   - flights is reached through its primary key index (flights_pkey), one
     lookup per booking via a Nested Loop. Memoize caches the result by
     flight_id, so only 13 index lookups were needed for 200 bookings
     (187 cache hits, 13 misses), one per distinct flight with bookings.
   - The Sort at the top is the ORDER BY b.booked_at.
   - The estimates match reality: the planner expected rows=200 at the join
     and the query returned rows=200.
   - EXPLAIN ANALYZE actually runs the query, which is why it shows actual
     times and row counts.
*/


/* Part B Questions:

   1: Identify the join algorithm or algorithms used.
      Two. A Hash Join joins bookings to passengers (Hash Cond:
      b.passenger_id = p.passenger_id), and a Nested Loop joins that result
      to flights. No Merge Join was used.

   2: Explain why PostgreSQL may have selected these algorithms, considering
      table sizes and available indexes.

      Hash Join: passengers is the smaller table (30 rows), so PostgreSQL
      builds a hash table from it and probes it once for each of the 200
      bookings. bookings has no index on passenger_id, so a full Seq Scan
      is the only way to read it, and both tables are small enough for that
      to be cheap.

      Nested Loop: flights.flight_id is the primary key, so each booking
      matches exactly one flight (rows=1) and an Index Scan using
      flights_pkey is a cheap lookup. Memoize caches the lookups by
      flight_id, so 200 bookings needed only 13 index searches (187 hits).

   3: Predict which part of the query might become less efficient as the
      dataset grows.

      The Seq Scan on bookings, since it is read in full and has no index on
      passenger_id or flight_id, and it would grow from 200 rows to more.
      The Sort on b.booked_at would also get slower and need more memory,
      because every joined row must be sorted before any are returned. The
      Hash Join's hash table (built from passengers) would only become a
      problem if passengers over grew. The flights lookups stay cheap because of the primary key index.
*/
