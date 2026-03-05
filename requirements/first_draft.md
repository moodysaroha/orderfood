1. Student App: The "Lock & Key" Experience
•	Subscription Gate: On first login, the app redirects to the "Plans" page. Access to the vendor list is blocked until a plan is active.
•	The Selection Screen: * List of Vendors (e.g., Oven Express, Kitchen Atte).
o	Menu for the day (e.g., Chole Bhature, Paneer Wrap).
•	The "Lock" Button: Available only during the 7 AM – 11 AM window for lunch only.
o	Logic Check: If a student tries to lock at 11:05 AM, the app shows: "Lock-in window closed. Please try again tomorrow!"
•	The QR Vault: Between 12 PM – 4 PM, a "Show QR" button appears for the locked meal. If not used by 4 PM, the credit is forfeited (or refunded based on your policy).
2. Vendor App: The "Kitchen Command"
•	Feature 1: Pre-Order Manifest:
o	A real-time list showing: Chole Bhature (45), Paneer Wrap (12), Thali (30).
o	This allows the vendor to know their workload before the lunch rush starts.
•	Feature 2: QR Scanner:
o	Used during the 12 PM – 4 PM window to verify the student actually locked this meal.
•	Feature 3: Menu Management:
o	A simple toggle system. Vendor can mark "Chole Bhature" as Sold Out for the next day's lock-in period if they run out of ingredients.
________________________________________
🗄️ Database Logic (The "State" Machine)
Your database needs to track the Status of a meal credit very carefully:
1.	Available: Student has credits but hasn't picked a meal.
2.	Locked: Student picked "Chole Bhature" (7 AM - 11 AM). Credit is "In Limbo."
3.	Consumed: Vendor scanned the QR (12 PM - 4 PM). Credit is officially spent.
4.	Expired: Student locked a meal but never showed up. (You keep the money, vendor gets paid for the prep).

The "Credit Coin" Logic
In this model, a "Credit Coin" is a digital currency. The student buys a bundle (e.g., 1coin *3 meal = 3 coins per day , 90 coins for 30 days).
1.	The "Daily Window" Rule: Every day at 11:01 AM, the system runs a "Cleanup Script."
2.	Scenario A (The Active Student): Student locks meal like- "Chole Bhature" before 11 AM. 1 Coin is moved to "Pending Vendor Payout."
3.	Scenario B (The No-Show): Student locks the meal but doesn't scan the QR by 4 PM. The Vendor still gets the coin value with deduction of some percentage of coin. The student gets no refund.
4.	Scenario C (The Passive Student): Student does not lock a meal by 11 AM. The System automatically deducts 1 Coin. This coin is your "Service Profit" .



---
# Updated App Blueprints

## 1. Student App: The "Lock & Key" Experience

- **Subscription Gate:** On first login, the app redirects to the "Plans" page. Access to the vendor list is blocked until a plan is active.
- **The Selection Screen:**
	- List of Vendors (e.g., Oven Express, Kitchen Atte)
	- Menu for the day (e.g., Chole Bhature, Paneer Wrap)
- **The "Lock" Button:** Available only during the **7 AM – 11 AM** window for lunch only.
	- Logic Check: If a student tries to lock at 11:05 AM, the app shows: _"Lock-in window closed. Please try again tomorrow!"_
- **The QR Vault:** Between **12 PM – 4 PM**, a "Show QR" button appears for the locked meal. If not used by 4 PM, the credit is forfeited (or refunded based on your policy).

## 2. Vendor App: The "Kitchen Command"

- **Pre-Order Manifest:**
	- A real-time list showing: Chole Bhature (45), Paneer Wrap (12), Thali (30)
	- This allows the vendor to know their workload before the lunch rush starts.
- **QR Scanner:**
	- Used during the **12 PM – 4 PM** window to verify the student actually locked this meal.
- **Menu Management:**
	- A simple toggle system. Vendor can mark "Chole Bhature" as Sold Out for the next day's lock-in period if they run out of ingredients.

---

## 🗄️ Database Logic (The "State" Machine)

Your database needs to track the status of a meal credit very carefully:

1. **Available:** Student has credits but hasn't picked a meal.
2. **Locked:** Student picked "Chole Bhature" (7 AM - 11 AM). Credit is "In Limbo."
3. **Consumed:** Vendor scanned the QR (12 PM - 4 PM). Credit is officially spent.
4. **Expired:** Student locked a meal but never showed up. (You keep the money, vendor gets paid for the prep).

---

## The "Credit Coin" Logic

In this model, a **Credit Coin** is a digital currency. The student buys a bundle (e.g., 1 coin × 3 meals = 3 coins per day, 90 coins for 30 days).

1. **The "Daily Window" Rule:** Every day at 11:01 AM, the system runs a "Cleanup Script."
2. **Scenario A (The Active Student):** Student locks meal (e.g., "Chole Bhature") before 11 AM. 1 Coin is moved to "Pending Vendor Payout."
3. **Scenario B (The No-Show):** Student locks the meal but doesn't scan the QR by 4 PM. The Vendor still gets the coin value with deduction of some percentage of coin. The student gets no refund.
4. **Scenario C (The Passive Student):** Student does not lock a meal by 11 AM. The System automatically deducts 1 Coin. This coin is your "Service Profit".

---

# Detailed App Features

## 1. Student App: The "Countdown" UI

To avoid complaints, the student needs to see the "danger" of losing a coin.

- **The Timer:** A countdown clock on the home screen: _"Time left to Lock your Meal: 02:45:12."_
- **The Warning:** If it’s 10:30 AM and they haven't locked a meal, send a Push Notification: _"Lock your Bite now or lose today's credit!"_
- **The Locking Mechanism:** Once they select a vendor and meal, the "Lock" button confirms the choice and generates the QR code (active only from 12 PM - 4 PM).

## 2. Vendor App: The "Pre-Order" Dashboard

- **Pre-Order List:** After 11 AM, the vendor sees a summary:
	- Total Meals to Prep: 120
	- Confirmed Revenue: (120 x Payout Rate)
- **QR Scanner:** To mark a "Locked" meal as "Picked Up."
- **Menu Updater:** Vendor can set the "Lock-In Menu" for the next day.

## 3. Admin Panel (Your View)

- **The "Sweep" Tool:** A dashboard to see how many coins were "Auto-Deducted" today vs. "Consumed."
- **Payout Calculator:** Automatically calculates how much to pay Oven Express based on Consumed + No-Show meals.

---

## ⚠️ Potential Risks to Manage

- **The "Upset Student":** Students will complain if they forget to lock. _Solution: Give them 5 "Rescue Pass" per month where they can reclaim an auto-deducted coin._
- **Vendor Integrity:** Ensure vendors actually have the food ready by 12 PM. If a student "Locks" but the vendor is out of food, you must have a "Vendor Strike".

---

# Student App: The "Lock-In" UI Mockup

The interface must emphasize the Time Windows so the student feels the urgency to act.

## 1. Home Screen (7 AM – 11 AM):

- **Top Bar:** "Balance: 12 🪙"
- **Urgency Timer:** Closing in 01:22:15 (Counts down to 11 AM).
- **Vendor List:** Cards showing Oven Express, Taco Bell, etc.
- **Action:** Tapping a vendor shows their specific "Bite Menu" (e.g., Chole Bhature).
- **The Button:** A large "🔒 LOCK MY BITE" button.

## 2. Home Screen (11:01 AM – 12 PM):

- **Status:** "Meal Locked at Oven Express."
- **Message:** "Kitchen is preparing your meal. Pickup starts at 12 PM."
- **Note:** If they didn't lock, the screen says: _"Daily Credit Deducted. See you tomorrow!"_

## 3. Pickup Screen (12 PM – 4 PM):

- **QR Code:** Large, high-brightness QR code.
- **Security:** "Valid for 60 seconds" (refreshes automatically).
Detailed App Features
1. Student App: The "Countdown" UI
To avoid complaints, the student needs to see the "danger" of losing a coin.
•	The Timer: A countdown clock on the home screen: "Time left to Lock your Meal: 02:45:12."
•	The Warning: If it’s 10:30 AM and they haven't locked a meal, send a Push Notification: "Lock your Bite now or lose today's credit!"
•	The Locking Mechanism: Once they select a vendor and meal, the "Lock" button confirms the choice and generates the QR code (active only from 12 PM - 4 PM).
2. Vendor App: The "Pre-Order" Dashboard
•	Pre-Order List: After 11 AM, the vendor sees a summary:
o	Total Meals to Prep: 120
o	Confirmed Revenue: (120 x Payout Rate)
•	QR Scanner: To mark a "Locked" meal as "Picked Up."
•	Menu Updater: Vendor can set the "Lock-In Menu" for the next day.
3. Admin Panel (Your View)
•	The "Sweep" Tool: A dashboard to see how many coins were "Auto-Deducted" today vs. "Consumed."
•	Payout Calculator: Automatically calculates how much to pay Oven Express based on Consumed + No-Show meals.
⚠️ Potential Risks to Manage
•	The "Upset Student": Students will complain if they forget to lock. Solution: Give them 5"Rescue Pass" per month where they can reclaim an auto-deducted coin.
•	Vendor Integrity: Ensure vendors actually have the food ready by 12 PM. If a student "Locks" but the vendor is out of food, you must have a "Vendor Strike" . 


Student App: The "Lock-In" UI Mockup
The interface must emphasize the Time Windows so the student feels the urgency to act.
1.	Home Screen (7 AM – 11 AM):
o	Top Bar: "Balance: 12 🪙"
o	Urgency Timer: Closing in 01:22:15 (Counts down to 11 AM).
o	Vendor List: Cards showing Oven Express, Taco Bell, etc.
o	Action: Tapping a vendor shows their specific "Bite Menu" (e.g., Chole Bhature).
o	The Button: A large "🔒 LOCK MY BITE" button.
2.	Home Screen (11:01 AM – 12 PM):
o	Status: "Meal Locked at Oven Express."
o	Message: "Kitchen is preparing your meal. Pickup starts at 12 PM."
o	Note: If they didn't lock, the screen says: "Daily Credit Deducted. See you tomorrow!"
3.	Pickup Screen (12 PM – 4 PM):
o	QR Code: Large, high-brightness QR code.
o	Security: "Valid for 60 seconds" (refreshes automatically).

