## **Task 5.4 — Recommendation Memo**

***The Memo:** You now know which producers fail often and which never started. Recommend a concrete action for each group. The producers who never started demand a different response from the ones who fail often, and saying so precisely is the point. Write for a non-technical reader.*

### **Recommendation**

The flights that fail often and the flights that never started are possible causes for this result and they lead to different next steps. The first group is selling but losing bookings. The second group has new flights that never started selling.



**Group 1: Flights that fail often (#11, #4 and #3)**

A "failure" here means a cancelled booking, which ends with no fare paid. About 16% of bookings fail on the larger flights (the 8 flights with 16 or more bookings). These three are above that:


| Flight         | Cancelled bookings | Evaluated Issue                                                              |
| -------------- | ------------------ | ---------------------------------------------------------------------------- |
| #11 (Japan)    | 5 of 16 (31%)      | Most cancellations of any flight, and the lowest average fare.               |
| #4 (Singapore) | 2 of 6 (33%)       | Highest share, but only 6 bookings, so one booking changes the result a lot. |
| #3 (Korea)     | 3 of 13 (23%)      | Most disputed bookings (2), and already marked inactive.                     |


**Recommended action:**

- **#11:** investigate before changing anything. It has real demand (16 bookings), so the aim is to find out why bookings fail. Ask customer support for the cancellation reasons and check when the failures happen and what the fares were.
- **#4:** keep it running and collect more bookings before deciding. Six bookings is too few to judge.
- **#3:** confirm whether it was closed on purpose. If so, leave it closed. If not, review the two disputed bookings first.



**Group 2: New Flights that never started selling (#14 and #15)**

These two flights have no bookings and no routes, even though both are marked active. They are not failing, because nothing was ever sold, so they should not be handled like Group 1.

**Recommended action:** check with the operations team whether these flights were  meant to launch and their plan launch date.

- **If yes,** assign their airports and open them for booking for launch date. Re-run the query after add and check performances after tickets sell.
- **If no,** mark them inactive so they stop showing up as available flights.



**Conclusion:**  
Fixing a failing flight means finding out why customers cancel or dispute. Nothing like that can be done for #14 and #15, since there are no customers yet. They need a decision about whether to launch or close them. Closing a failing flight without finding the cause could throw away real demand, as #11 has.

The data shows which flights fail and which never started. It does not show why. Cancellation reasons, timing, pricing and launch plans are needed to answer that, and the actions above are meant to collect them.