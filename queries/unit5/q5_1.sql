--Task 5.1 — the three-table join, the junction traversal, and the self join.
-- Mapping: actor = passengers, producer = flights, event = bookings,
--          catalog = airports, junction = flight_routes, metric = fare_paid


/* ============================================================
   Question 1
   Who are the passengers behind the bookings? Write a query that joins
   three tables (passengers, bookings, flights) to display the passengers
   who made each booking, the flights associated with the bookings, and
   the bookings' date and time.
   ============================================================ */

SELECT p.passenger_id, p.passenger_name, f.flight_id, f.flight_number,
       b.booking_id, b.booked_at, b.booking_status, b.fare_paid
FROM bookings b
JOIN passengers p ON p.passenger_id = b.passenger_id
JOIN flights    f ON f.flight_id    = b.flight_id
ORDER BY b.booked_at;

/* Result analysis:
   The query returned 200 rows, every booking matches a
   passenger and a flight. For example, Passenger_01 booked VN201 on
   2023-01-01 15:48 (cancelled, 0.00), and Passenger_20 booked VN209 on
   2023-01-05 14:18 (confirmed, 25.89). The result shows who is behind each
   booking and when. booking_status and fare_paid are kept so it ties back
   to the Unit 4 zero-fare finding.
*/


/* ============================================================
   Question 2
   Do the flights identified in Assignment 4 share certain airports
   credentials or tags? Write a query that connects the flights table to
   the airports table through the flight_routes table. Return the flights
   associated with your theme's airports tag.
   ============================================================ */

-- Airport tag is labeled as iata_code
SELECT f.flight_id, f.flight_number, f.origin_country, a.iata_code, fr.effective_from
FROM flights f
LEFT JOIN flight_routes fr ON fr.flight_id = f.flight_id
LEFT JOIN airports a       ON a.airport_id = fr.airport_id
WHERE f.flight_id IN (3, 4, 11, 15)
ORDER BY f.flight_id, a.iata_code;

/*Result analysis:
   - The flights pair up on shared airports: #3 and #4 share HAN, #3 and #11
     share SIN, and #4 and #11 share ICN.
   - No airport is common to all three flights that have routes.
   - SGN serves 9 of 15 flights, so it does not tell the flights apart.
   - #15 has no flight_routes rows, LEFT JOINs keep the result
     with NULL airport. An inner join would have dropped it silently.
*/


/* ============================================================
   Question 3
   How do the flights compare with one another? Write a self join to compare records within the flights table. 
   Use the results to explore whether the flights identified in Assignment 4 share characteristics
   with other flights or whether differences in activity levels (number of bookings) may explain their performance (fare_paid).
   ============================================================ */

-- Compares each Unit 4 flight with the other flights from the same origin country.
WITH s AS (
  SELECT f.flight_id, f.origin_country, f.seat_capacity,
         COUNT(b.booking_id)                   AS bookings,
         COUNT(*) FILTER (WHERE b.fare_paid=0) AS zero_fare,
         ROUND(AVG(b.fare_paid), 2)            AS avg_fare
  FROM flights f LEFT JOIN bookings b ON b.flight_id = f.flight_id
  GROUP BY f.flight_id, f.origin_country, f.seat_capacity)
SELECT a.flight_id AS flight_a, b.flight_id AS flight_b, a.origin_country,
       a.seat_capacity AS cap_a, b.seat_capacity AS cap_b,
       a.bookings AS bk_a, b.bookings AS bk_b,
       a.zero_fare AS zero_a, b.zero_fare AS zero_b,
       a.avg_fare AS avg_a, b.avg_fare AS avg_b
FROM s a JOIN s b ON a.origin_country = b.origin_country AND a.flight_id < b.flight_id
WHERE a.flight_id IN (3,4,11,15) OR b.flight_id IN (3,4,11,15);

/* Result summary (flight A / flight B):

   Pair                          | Capacity  | Bookings        | Zero-fare | Avg fare
   ------------------------------+-----------+-----------------+-----------+--------------
   #3 vs #5   (Korea)            | 320 / 320 | 13 / 18         | 3 / 3     | 13.36 / 23.06
   #3 vs #12                     | 320 / 115 | 13 / 17         | 3 / 2     | 13.36 / 18.27
   #3 vs #13                     | 320 / 166 | 13 / 11         | 3 / 1     | 13.36 / 19.86
   #11 vs #2  (Japan)            | 193 / 320 | 16 / 16         | 5 / 4     | 11.94 / 17.02
   #11 vs #6                     | 193 / 90  | 16 / 21         | 5 / 4     | 11.94 / 17.84
   #4 vs #9   (Singapore)        | 320 / 280 | 6 / 14          | 2 / 4     | 19.49 / 14.17
   #15 vs #1, #7, #8 (Thailand)  | n/a       | 0 vs 11, 18, 20 | n/a       | no fares

/*Result analysis:
- Capacity doesn't explain the gaps. Flights #3 and #5 both have 320 seats, but #3 averages 13.36 against 23.06.
- Within each country, the flights with the weakest numbers also have the most zero-fare bookings (cancelled or disputed): #3, #11 and #4.
- Part of the gap is plain volume. #3 has fewer bookings than #5 (13 vs 18) for the same 3 zero-fare bookings, so its zero-fare share is higher.
- #11 is different. It has the same 16 bookings as #2, so volume doesn't explain it, and its average fare is lower. That points to something specific to the flight or route, such as pricing, cancellations or timing.

Possible issues:
1. Averages include the 0.00 fares. Cancelled bookings count as 0, which pulls #3 and #11 down. Compare confirmed-only fares before judging them.
2. The samples are small. #4 has 6 bookings, so one booking moves its numbers a lot. Treat it as inconclusive.
3. Same-country pairs only. The self join compares flights from the same origin country, so it says nothing about flights across countries.
4. #14 and #15 are a data question. They have no bookings and no routes, so there is nothing to compare.
5. Bookings are tiny compared with seats. Every flight is under 25% of its seat capacity, and most are under 10%. Low volume applies to the whole dataset, so low booking alone is a weak reason to cut a flight.

Flights that need caution:

- #4
  - Why: Fewest bookings (6, 1.9% of seats), 33% zero-fare, lowest revenue (116.92).
  - Reason: The sample is too small, so wait for more data. Its avg fare of 19.49 is fine.

- #3
  - Why: 23% zero-fare, lowest avg fare among the larger flights, already inactive (is_active = false).
  - Reason: It is already inactive, so the decision is mostly made.

- #11
  - Why: Highest zero-fare share among flights with 16 or more bookings (31%), lowest avg fare (11.94).
  - Reason: Check confirmed-only fares before cutting. It has the second-highest booking count after #6.

- #14, #15
  - Why: No bookings, no routes.
  - Reason: These are data-question candidates, not cut-or-keep candidates. Check whether they were ever launched.
*/