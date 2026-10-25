## *Name the person who would act on the per-producer (flights) breakdown, and say what the aggregate hides?*
- Flight or route director (enterprise and regional level) who decide the flight route status and fundings.
- The aggregated results show that cancelled bookings have a 0.00 fare paid. This can affect the total calculation when analyzing the data (one reason they are removed from the average calculation) and the failure rate.
- Aggregated total bookings include disputed and cancelled bookings. To investigate the cause, examine each possible failure flight's data individually, as mentioned in q4_1.sql (flights #3, #11, #15).
- The flight fare average is not diverse, and the booking count does not show the booking status percentage until you compare flights with large capacity. For example, flight #2 has a capacity of 320 and can have a similar booking count (16 vs. 17 bookings) as a smaller-capacity flight like flight #7, which has 90 capacity.


## *An average conceals its distribution, a count conceals who is counted. What would you need to see next?*
- Cancelled bookings have a 0.00 fare. We can compare the LEFT JOIN and JOIN queries to determine whether zero-fare cancellations affect the average.
- Correlate passenger information with cancelled and disputed flights to determine which passenger population contributes most to failed flights.
- Identify the seasons and timing that contribute to cancelled and disputed flights.
- Examine the correlation between check-in, cancellation reason, and booking status. Determine whether NULL reasons affect the results. (The cancellation reason is also related to the 0.00 fare paid.)

