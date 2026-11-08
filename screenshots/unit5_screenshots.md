### unit 5 Screenshots SQL
## Task 5.1 — the three-table join, the junction traversal, and the self join (q5_1.sql)
>## 1 - Who are the passengers behind the bookings? Join passengers, bookings, and flights.

- Each booking is shown with the passenger who made it, the flight, and the booking date and time (200 rows). 

![Alt text](q5_1.1.png)


>## 2 - Do the flights identified in Assignment 4 share certain airports tags? Connect flights to airports through flight_routes.

- Flights #3, #4, #11 and #15 with their airport codes (iata_code). Flight #15 has no routes, so LEFT JOIN keeps it with NULL airport values.

![Alt text](q5_1.2.png)


>## 3 - How do the flights compare with one another? Self join on flights.

- Each Unit 4 flight compared with other flights from the same origin country (capacity, booking count, zero-fare count, average fare). Flight #15 has no bookings, so its average fare is NULL.

![Alt text](q5_1.3.png)


------------
## Task 5.2 — LEFT, RIGHT, and FULL OUTER joins, plus NOT EXISTS and EXCEPT (q5_2.sql)
>## Part A: Compare INNER JOIN and LEFT JOIN

- LEFT JOIN returns all 15 flights, including flights #14 and #15 with booking_count 0.

![Alt text](q5_2a.1.png)


- INNER JOIN returns only the 13 flights that have bookings. Flights #14 and #15 do not appear.

![Alt text](q5_2a.2.png)


- Count of flights excluded by the inner join: 15 in the left join, 13 in the inner join, 2 excluded.

![Alt text](q5_2a.3.png)


- Which flights are missing: #14 (VN214, Vietnam) and #15 (VN215, Thailand). Both are active.

![Alt text](q5_2a.4.png)


>## Part B: Explore RIGHT JOIN and FULL OUTER JOIN

- RIGHT JOIN (bookings on the left, flights on the right) returns the same 15 flights as the LEFT JOIN.

![Alt text](q5_2b.1.png)


- Verification that the LEFT JOIN and RIGHT JOIN results match: 15 rows each and 0 rows different in either direction (EXCEPT).

![Alt text](q5_2b.2.png)


- FULL OUTER JOIN: 202 total rows, 200 matched, 2 flights without bookings, 0 bookings without flights.

![Alt text](q5_2b.3.png)


>## Part C: Find producers with no events using two approaches

- Approach 1, NOT EXISTS: flights #14 and #15.

![Alt text](q5_2c.1.png)


- Approach 2, EXCEPT: the same flight ids, 14 and 15.

![Alt text](q5_2c.2.png)


- Comparison of the two approaches: 0 flights found by only one approach, so they identify the same producers.

![Alt text](q5_2c.3.png)


------------
## Task 5.3 — the CROSS JOIN and the EXPLAIN statement (q5_3.sql)
>## Part A: Explore CROSS JOIN

- Step 1: row count of each source table. flights has 15 rows and airports has 5 rows.

![Alt text](q5_3a.1.png)


- Step 2: the CROSS JOIN (first 10 rows). Every flight is paired with every airport.

![Alt text](q5_3a.2.png)


- Step 3: the CROSS JOIN returns 75 rows, which matches 15 flights x 5 airports = 75.

![Alt text](q5_3a.3.png)


>## Part B: Examine a Query Execution Plan

- EXPLAIN of the three-table join from Task 5.1: Hash Join (bookings and passengers), Nested Loop with Memoize and an Index Scan on flights_pkey, and a Sort at the top.

![Alt text](q5_3b.1.png)


- EXPLAIN ANALYZE of the same query, with actual row counts, buffer use, and timings.

![Alt text](q5_3b.2.png)
