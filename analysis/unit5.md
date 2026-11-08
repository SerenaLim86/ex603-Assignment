## Write-ups for Tasks 5.1, 5.2, and 5.3, plus the reflection and your reading of the plan.

## Task 5.1 - **Connect Producers to Their Data**

1. **What feature or report on your platform could use the three-table** (passengers, bookings, flights)  **join from Question 1? What information would it display?**

A booking-history report for customer service and operations could use the three-table (passengers, bookings, flights)  join . The report would list each passenger, the flight, and the booking date and time. Staff could look up one passenger's trips or review cancelled and disputed bookings, which Unit 4 flagged for flights #3, #11 and #15. It would also let them check timing patterns, such as seasons with more cancellations.



2. **Why is the flight_routes table important for answering Question 2? What would make this analysis more difficult without it?**

flight_routes table display  flight that serve several airports and an airport can serve several flights, and `flight_routes` is the table that holds that many-to-many link. Without it, the airports would have to be repeated in extra columns on `flights`, or each flight would be duplicated once per airport.`flight_routes` also stores `effective_from`, which a single column on `flights` could not hold per airport.

--

## Task 5.2 - **Find Records That Joins May Exclude**

1. **Which flights were excluded by the inner join? Report their identifiers.**

Two of the 15 flights were excluded: flight_id **14** (VN214, Vietnam, 303 seats) and flight_id **15** (VN215, Thailand, 132 seats). The LEFT JOIN, RIGHT JOIN, FULL OUTER JOIN, NOT EXISTS and EXCEPT queries all returned these same two flights.



2. **What does it mean when a flights has no booking? What are some possible explanations?**

The result queries shows that flights #14 and #15 have bookings. Both are marked active (`is_active = true`), and neither has any `flight_routes` rows. The data does not explain, but possible reasons are:

- The flight was set up/ new, and  not launched for passenger sales
- Booking data for the flight was not updated or was lost (a data-completeness problem).
  - The flight has no route or airport assigned, so passengers cannot find or book it.
  - The flight is an old record that should have been marked inactive.



3. **How could a report based only on an inner join give leadership an incomplete picture of the platform?**

An inner join drops flights with no bookings, so a report would show 13 flights instead of 15 and never mention #14 and #15.

- **Data shows:** the inner join returns 13 flights, and averages such as fare per flight would be calculated only over flights that already have bookings.
- **Needs investigation:** whether the missing flights matter to the business (for example, whether the 435 seats on #14 and #15 were meant to be sold).



4. **Why might leadership want to identify flights  have never been active?**

This is because non active flights could either be the flight created no longer needed from the business due to no booking or the data was inserted incorrectly causing flight showing non-active or no booking.



5. **What action could leadership take based on these findings?**

- Check whether #14 and #15 were ever launched or if it is planning to be. If they are real flights, add their routes in `flight_routes` and review why they have no bookings. If they were never launched and no longer active, mark as inactive.
- If they were existing flights, investigate why booking and route data were missing.
- Then recheck after update using LEFT JOIN or NOT EXISTS to confirm status.



--

## Task 5.3 - **Understand Join Performance and Execution Plans**

1. **Give an example of when a Cartesian product could be useful on your platform, or explain why you would not need one.**

It is useful for listing every possible flight and airport combination, to find routes that could be added. `flights CROSS JOIN airports` gives 15 × 5 = 75 combinations; 25 exist in `flight_routes` and 50 do not. For example, flight #3 has no route to ICN, NRT or SGN.

```sql
SELECT f.flight_id, a.iata_code
FROM flights f
CROSS JOIN airports a
WHERE NOT EXISTS (SELECT 1 FROM flight_routes fr
                  WHERE fr.flight_id = f.flight_id AND fr.airport_id = a.airport_id);
```

I would not use one between `bookings` and `passengers`: 200 × 30 = 6,000 rows, given almost all meaningless pairs.



2. **Which join algorithms did PostgreSQL choose for your query?**

The plan in `q5_3.sql`, PostgreSQL chose a Hash Join for `bookings` and `passengers` (`Hash Cond: b.passenger_id = p.passenger_id`) and a Nested Loop to join the result to `flights`. 



3. **What information in the execution plan helps explain those choices?**

- **Hash Join:** `passengers` is the smaller table (30 rows) and is hashed (`Buckets: 1024, Batches: 1, Memory Usage: 10kB`). Each of the 200 `bookings` rows probes it once. Both tables use a Seq Scan because they are small.
- **Nested Loop:** the join column on `flights` is its primary key, so the plan uses `Index Scan using flights_pkey` with `Index Cond: flight_id = b.flight_id`, and each booking matches one flight (`rows=1`). Memoize (`Cache Key: b.flight_id`) caches the result: 187 hits and 13 misses, one lookup per distinct flight.



4. **Why is it useful to understand the selected join algorithms?**

The algorithm shows how the query will behave as the data grows. A Nested Loop is fast when each lookup uses an index, but without one it would rescan the inner table once per outer row. Reading the plan helps  find which join to fix and where an index is missing when debugging.



5. **What changes to the data or database might make another join algorithm more appropriate?**

- If `bookings` grew to millions of rows and the query filtered to one passenger, an index on `bookings.passenger_id` would make a Nested Loop with Index Scan better than hashing everything.
- If `flights` grew large and was joined without a filter, a Hash Join or Merge Join would likely replace the Nested Loop, because millions of index lookups cost more than one pass.
- The estimate for `passengers` was  100 rows but the actual was 30 rows, so running `ANALYZE` to refresh table statistics would keep the planner's choices accurate.



--

### **Reflection (150–250 words)**

*In Task 5.3, you examined the execution plan for your three-table join. Reflect on the following question:*

*Consider factors such as table size, indexes, and the number of matching records. Include your reflection in /analysis/[unit5.md](http://unit5.md).*

 

1. **What changes to your data or database schema might cause PostgreSQL to choose a different join algorithm?**

In my three-table join, PostgreSQL chose a Hash Join for bookings and passengers and a Nested Loop for flights. If my data grows or I add indexes, I expect that can change the algorithm use. Today bookings has 200 rows and passengers has 30, if bookings grew to millions of rows, I think PostgreSQL would still hash the small passengers table, but it might use a Merge Join for flights instead of millions of index lookups. A for index, my schema only has primary key indexes, so bookings.passenger_id has none. If I added one and filtered to a single passenger, ex. booking-history report, I expect a Nested Loop with an index scan. The number of matching records matters because my join  returns 200 rows, so indexed lookups will be use if a filter matching few bookings, but hashing will be selected when only one has matching.



2. **Explain how these changes could influence query performance.**

My query executed in 0.555 ms, so the algorithm makes no visible difference today. With millions of bookings, the Seq Scan on bookings would become the slow part, and without an index on bookings.passenger_id, every lookup of one passenger's trips would scan the whole table. A Hash Join would also need more memory, and if the hash table no longer fit it would spill to disk, where my plan shows Batches: 1. Stale statistics are another risk: the plan estimated 100 passengers but found 30, so I would run ANALYZE and compare plans with EXPLAIN ANALYZE, as I did in q5_3.sql.

