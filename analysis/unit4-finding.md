**Task 4.3 — the breakdown for leadership**

**The Breakdown:**

*What is the true failure rate, how does it vary across producers, and which two or three producers would you actually investigate? Report by identifier. Write for a reader who does not write SQL.*

- The average zero-fare failure rate for the 8 flights with 16 or more bookings is 16%. More analysis is needed, as stated in the unit4.md file, including correlation analysis of flight timing and season, cancellation reason, and check-in status, before deciding which flight routes need cancellation or modification. However, from the data in this exercise, flights #4, #11, #3, and #15 need further analysis for the following reasons:
    - Flights #4 and #11 have the highest zero-fare shares.
    - Flight #15 from Thailand has 0 confirmed bookings.
    - Flight #11 from Japan has the most cancellations (5).
    - Flight #3 from Korea has the most disputed bookings (2).



**Reflection (150–250 words):**

*Conditional aggregation computes several answers in one pass over the data. Contrast that with running two separate filtered queries. At a million rows, why does the difference matter?*

The data we are seeing in this exercise is very small compared to real-world data with millions of rows. Using the zero-paid example for flights with 16 or more bookings, one flight with one or two additional cancellations can increase the average zero-paid share significantly, whereas in a dataset of a million rows the same change would barely move it.

With two separate filtered queries for the zero-paid count and the total, if flight bookings change between runs, the share can also change, causing the final numbers to mismatch between the two queries. One pass makes it simpler to update the data and avoids unreconciled results.