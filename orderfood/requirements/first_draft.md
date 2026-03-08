i want to create a flutter android app.
login screen i'll set up later.
my requirement is - 
user is a restaurant vendor. app will be using sdui.
Server-Driven UI (SDUI)
The key technique is Server-Driven UI — the server sends not just data, but instructions on how to render the UI.
Instead of hardcoding layouts in the app, the app downloads a JSON/config payload that describes what components to show, in what order, with what content.
user must be able to upload/mark sold out/ back in stock etc from json. i (developer) must be able to update the ui completely from backend so users wont have to keep updating the app.
the ui will show total orders booked today - this will come from student login which students will use to book food items from the same app from student login.
a dashboard for vendor - 
1. orders booked today
2. total revenue today
4. total overall revenue since sign up
other important features - you decide
menu screen for managing stock - changes done here will be reflected to the students instantly since we are using sdui.
this menu will be where vendor can also upload images directly from the app and students will be able to see the images.

I want backend to be in node/typescript.
I want to follow solid pattern and relevant design patterns for easy maintenace in both flutter and node/typescript.    