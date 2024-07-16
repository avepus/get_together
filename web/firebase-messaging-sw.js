importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

// todo Copy/paste firebaseConfig from Firebase Console
const firebaseConfig = {
    apiKey: "AIzaSyAj4Q9rzICUtz9qhGLmEp9DCem2i-VitlM",
    authDomain: "avepus-get-together.firebaseapp.com",
    projectId: "avepus-get-together",
    storageBucket: "avepus-get-together.appspot.com",
    messagingSenderId: "769257794479",
    appId: "1:769257794479:web:0ec1127e9fa4a4dbe3dd5a",
    measurementId: "G-8V3Z6XHRP7"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// todo Set up background message handler
messaging.onBackgroundMessage((message) => {
    console.log("onBackgroundMessage", message);
   });