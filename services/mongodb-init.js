// This is a javascript file for initializing mongodb
// Please Create a database "restaurants" and a collection "restaurants" in the database
db = db.getSiblingDB("restaurants");

db.restaurants.insertMany([
  {
    name: "Pasta Paradise",
    address: "123 Spaghetti Lane",
    style: "Italian",
    vegetarian: "no",
    open_hour: "10:00",
    close_hour: "22:00",
    deliveries: "yes",
  },
  {
    name: "Seoul Food",
    address: "789 Kimchi Blvd",
    style: "Korean",
    vegetarian: "yes",
    open_hour: "11:00",
    close_hour: "23:00",
    deliveries: "no",
  },
  {
    name: "French Fries",
    address: "456 Baguette St",
    style: "French",
    vegetarian: "no",
    open_hour: "12:00",
    close_hour: "21:00",
    deliveries: "yes",
  },
]);
