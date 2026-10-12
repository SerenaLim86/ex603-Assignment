*The memo*

#Two to three paragraphs addressed to the team that owns the dashboard:

- State what the dashboard reported, what the data actually shows, where the error came from, and what should happen to the frozen payout. Write for a reader who does not write SQL: no queries, and no jargon they would not already know.

The data on passenger no-shows in bookings shows that many cancellation reasons are missing. This is because no NOT NULL rules were previously set, allowing inserts with values such as Payment failed and Passenger cancelled. This caused counts in the reporting to be inaccurate.

Outside of the no-show NULL issue, many attributes also did not have NOT NULL constraints:

- bookings --NULL found in cancellation_reason, checked_in_at
- passenger -- entire Table is empty
- passengers -- NULL found in referred_by

The passenger table should be combined with the passengers table to avoid duplicated data. This could also cause incorrect results if someone accidentally queries the empty table and gets no data returned.

To help the team remove the frozen payout from leadership due to passenger no-shows on their bookings, the team needs to find the remaining NULL cancellation reasons and see whether that changes the total passenger no-show count. After that, they should look at which flight routes are associated with those booking IDs and decide whether the route is profitable, given that this was reviewed in the route profitability review. Disputed-booking analysis also comes into play after identifying all bookings with passenger no-shows; the team can then see whether those bookings are correlated and what caused the disputes.