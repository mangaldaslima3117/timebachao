const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { format, parseISO } = require('date-fns');
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { sendEmail } = require("./email");
admin.initializeApp();

exports.sendBookingNotification = onDocumentCreated("bookings/{bookingId}", async (event) => {
    const booking = event.data?.data();
    console.log("sendBookingNotification executed :");
    console.log(booking);
    if (!booking) return;

    // Fetch all available maids
    const availableMaidsSnapshot = await admin
        .firestore()
        .collection("maids")
        .where("isAvailable", "==", true)
        .get();

    const maidTokens = availableMaidsSnapshot.docs
        .map(doc => doc.data()?.fcmToken)
        .filter(token => !!token);

    console.log(`Found available maids with FCM tokens.`);
    console.log(maidTokens);

    // Fetch all available maids
    const availableAdminSnapshot = await admin
        .firestore()
        .collection("users")
        .where("role.roleType", "==", 'Admin')
        .get();

    const adminTokens = availableAdminSnapshot.docs
        .map(doc => doc.data()?.fcmToken)
        .filter(token => !!token);

    // // Get Admin token
    // const adminDoc = await admin.firestore().collection("users").doc("6V8CwSpvbQUxaFfsxMTfZ3Ii4cw1").get();
    // const adminToken = adminDoc.data()?.fcmToken;
    console.log(`Found available admin with FCM tokens.`);
    console.log(adminTokens);
    console.log("Booking from " + booking["customerInfo"]["name"] + " at " + booking["bookedOn"]);

    // const allTokens = [...maidTokens, adminTokens].filter(token => typeof token === 'string' && token.length > 0);
    const allTokens = [...maidTokens].filter(token => typeof token === 'string' && token.length > 0);
    console.log(allTokens);
    if (allTokens.length === 0) {
        console.log("⚠️ No tokens to send notification to.");
        return;
    }

    //const bookedOnDate = booking["bookingDate"].toDate(); // Firestore Timestamp to JS Date
    const parsedDate = parseISO(booking["bookingDate"]);

    const formattedDate = format(parsedDate, 'dd-MM-yyyy HH:mm');

    const message = {
        notification: {
            title: "New Booking 📅",
            body: `"Booking from ${booking["customerInfo"]["name"]} on ${formattedDate}"`,
        },
        data: {
            type: "booking",
            bookingId: booking["bookingId"],
            screen: "BookingDetailsPage",
        },
        android: {
            notification: {
                sound: "default",
                clickAction: "FLUTTER_NOTIFICATION_CLICK", // Required for Android foreground
            },
        },
        apns: {
            payload: {
                aps: {
                    sound: "default",
                },
            },
        },
        tokens: allTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Notifications sent to ${response.successCount} devices.`);
});


//CHECK PENDING BOOKINGS AND NOTIFY ADMIN
exports.checkPendingBookingsAndNotifyAdmin = onSchedule("every 2 minutes", async () => {
    console.log("⏰ Running check for pending bookings...");

    // Step 1: Fetch the threshold from app_account
    const appAccountSnap = await admin
        .firestore()
        .collection("app_accounts")
        .doc("q35FN8T1MUBjb7XokFjl") // replace with actual ID if needed
        .get();

    const appAccount = appAccountSnap.data();
    if (appAccount !== null) {
        console.log("App Account Data: ", appAccount);
        console.log("BookingNotifications : " + appAccount?.sendPendingBookingNotifications);
    }

    if (!appAccount?.sendPendingBookingNotifications) {
        console.log("⚠️ Pending booking notifications are disabled in app_account.");
        return;
    }

    const now = Date.now();
    const thresholdInMinutes = appAccount?.pendingBookingReminderThresholdMinutes ?? 2;
    const thresholdMillis = thresholdInMinutes * 60 * 1000;

    const today = new Date().toISOString().split('T')[0]

    // Step 2: Get bookings that are still pending
    console.log("Fetching booking details started for today: " + today);
    const bookingsSnapshot = await admin
        .firestore()
        .collection("bookings")
        .where("serviceStatus", "==", "1") // Assuming "1" means BOOKED but not yet confirmed
        .where("bookedOn", "==", today)
        .get();

    console.log(`Found ${bookingsSnapshot.size} pending bookings for today.`);

    const staleBookings = bookingsSnapshot.docs.filter((doc) => {
        const booking = doc.data();
        const bookedOn = new Date(booking.bookingDate).getTime();
        return booking.serviceStatus === "1";
    });

    console.log("Fetching booking details completed." + staleBookings.length + " stale bookings found.");

    if (staleBookings.length === 0) {
        console.log("✅ No stale pending bookings found.");
        return;
    }

    // Step 3: Get admin FCM tokens
    const adminSnapshot = await admin
        .firestore()
        .collection("users")
        .where("role.roleType", "==", "Admin")
        .get();

    const adminTokens = adminSnapshot.docs
        .map((doc) => doc.data()?.fcmToken)
        .filter((token) => typeof token === "string" && token.length > 0);

    if (adminTokens.length === 0) {
        console.log("⚠️ No admin FCM tokens found.");
        return;
    }

    // Step 4: Send notifications for each stale booking
    const notificationPromises = staleBookings.map(async (doc) => {
        try {
            const booking = doc.data();

            const message = {
                notification: {
                    title: "⏰ Pending Booking Alert",
                    body: `Booking by ${booking.customerInfo?.name ?? "Unknown"}, Booking Id#${booking.bookingId ?? ""} is still pending.`,
                },
                data: {
                    type: "booking_pending_alert",
                    bookingId: booking.bookingId,
                    screen: "BookingDetailsPage",
                },
                android: {
                    notification: {
                        sound: "default",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
                tokens: adminTokens,
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`📣 Sent reminder for booking ${booking.bookingId} to ${response.successCount} admin(s).`);
        } catch (error) {
            console.error(`❌ Failed to send reminder for booking ${doc.id}`, error);
        }
    });

    // Wait for all to finish, whether success or failure
    await Promise.allSettled(notificationPromises);

    console.log(`✅ Notifications sent for ${staleBookings.length} stale bookings.`);
    console.log("⏰ Finished checking for pending bookings.");
});

exports.notifyCustomerOnBookingUpdate = onDocumentUpdated("bookings/{bookingId}", async (event) => {
    const bookingBefore = event.data.before;
    const bookingAfter = event.data.after;

    if (!bookingAfter.exists) {
        console.log("No booking data found.");
        return;
    }

    const bookingData = bookingAfter.data();  // ✅ Correct
    console.log(bookingData);
    const phoneNumber = bookingData["customerInfo"]["phone"];
    const bookingId = bookingData["bookingId"];

    if (!phoneNumber) {
        console.log("No phone number in booking.");
        return null;
    }

    try {
        // Get customer document using phone number as docId
        const customerDoc = await admin.firestore()
            .collection("customers")
            .doc(phoneNumber)
            .get();

        if (!customerDoc.exists) {
            console.log(`Customer with phone ${phoneNumber} not found.`);
            return null;
        }

        const fcmToken = customerDoc.data().fcmToken;

        const allTokens = [fcmToken];
        console.log(allTokens);

        if (!fcmToken) {
            console.log(`No FCM token for customer ${phoneNumber}`);
            return null;
        }

        // Prepare message based on status
        const bookingStatus = bookingData["paymentInfo"]["status"] === "6" ? bookingData["paymentInfo"]["status"] : bookingData["serviceStatus"];

        let statusMessage = "Your booking has been accepted!";
        let confirmMessage = "";
        switch (bookingStatus) {
            case "2":
                statusMessage = `Your booking #${bookingId} has been accepted!`;
                confirmMessage = "Booking Confirmed";
                break;
            case "3":
                statusMessage = `The maid has started working on your booking #${bookingId}.`;
                confirmMessage = "Service Started";
                break;
            case "4":
                statusMessage = `Your booking #${bookingId} has been completed. Thank you!`;
                confirmMessage = "Service Completed";
                break;
            case "5":
                statusMessage = `Your booking #${bookingId} has been cancelled !`;
                confirmMessage = "Booking Cancelled";
                break;
            case "6":
                statusMessage = `Payment for your booking #${bookingId} is success, Thank you !`;
                confirmMessage = "Payment Confirmed";
                break;
            default:
                statusMessage = `There’s an update on your booking #${bookingId}.`;
                confirmMessage = "Notification Update";
        }

        // Compose the push notification
        const message = {
            notification: {
                title: confirmMessage,
                body: statusMessage,
            },
            data: {
                bookingId: bookingId,
                type: "booking_created",
            },
            token: fcmToken,
        };


        const response = await admin.messaging().send(message);
        console.log(`Notification sent to ${phoneNumber} for booking ${bookingId} ${response.successCount} notifications sent.`);
    } catch (error) {
        console.error("Error sending notification:", error);
    }

    return null;
});

exports.sendEmailToCustomerOnBookingUpdate = onDocumentUpdated("bookings/{bookingId}", async (event) => {
    console.log("sendEmailToCustomerOnBookingUpdate execution started :");
    const bookingAfter = event.data.after;

    if (!bookingAfter.exists) {
        console.log("No booking data found.");
        return;
    }
    const bookingData = bookingAfter.data();  // ✅ Correct
    console.log(bookingData);// ✅ Correct
    const status = bookingData["serviceStatus"] === "4" ? bookingData["paymentInfo"]["status"] : bookingData["serviceStatus"];
    const customerEmail = bookingData["customerInfo"]["email"];
    const customerName = bookingData["customerInfo"]["name"];
    const parsedDate = parseISO(bookingData["bookingDate"]);

    const formattedDate = format(parsedDate, 'dd-MM-yyyy');

    let subject = "", message = "";
    console.log("Service Status: " + status);
    console.log("Customer Name: " + customerName);
    console.log("Customer Email: " + customerEmail);
    switch (status) {
        case "1":
            subject = "Booking Placed";
            message = `Hi ${customerName}, your booking has been placed.`;
            break;
        case "2":
            subject = "Booking Accepted";
            message = `Hi ${customerName},
Your service booking (ID: ${bookingData["bookingId"]}) has been successfully confirmed. 
Our service provider will reach you as scheduled on or before ${bookingData["timeSlot"]["startTime"]} on ${formattedDate}.

Thank you for choosing us!

— Team Time Bachao`;
            break;
        case "6":
            subject = "Payment Successful";
            message = `Hi ${customerName},

Your service (Booking ID: ${bookingData["bookingId"]}) has been successfully completed.

Total Paid: ₹${bookingData["paymentInfo"]["amount"]}  
Payment Mode: ${bookingData["paymentInfo"]["method"]}

We hope you had a great experience. Thank you for using Time Bachao App!

— Team Time Bachao`;
            break;
        default:
            return;
    }

    // console.log('Customer email', customerEmail !== undefined && customerEmail !== null && customerEmail !== "");
    console.log(`Sending email to ${customerEmail} with subject "${subject}"`);
    await sendEmail({ to: customerEmail, subject, text: message });
});


exports.sendAssignmentNotification = onDocumentUpdated("bookings/{bookingId}", async (event) => {
    const bookingBefore = event.data.before;
    const bookingAfter = event.data.after;

    if (!bookingAfter.exists) {
        console.log("No booking data found.");
        return;
    }

    const bookingData = bookingAfter.data();  // ✅ Correct
    console.log(bookingData);
    const phoneNumber = bookingData["customerInfo"]["phone"];
    const bookingId = bookingData["bookingId"];
    const maidId = bookingData["maidId"];
    const maidName = bookingData["maid"]["name"];
    const serviceDate = bookingData["timeSlot"]["serviceDate"]

    if (!maidId) {
        console.log("No assigned maid for booking.");
        return null;
    }

    try {
        // Get customer document using phone number as docId
        // Fetch assigned maid details
        const maidDoc = await admin.firestore().collection("maids").doc(maidId).get();

        if (!maidDoc.exists) {
            console.log(`Maid with ID ${maidId} not found.`);
            return null;
        }

        const fcmToken = maidDoc.data().fcmToken;

        const allTokens = [fcmToken];
        console.log(allTokens);

        if (!fcmToken) {
            console.log(`No FCM token for maid ${maidId}`);
            return null;
        }

        // Prepare message based on status
        const bookingStatus = bookingData["paymentInfo"]["status"] === "6" ? bookingData["paymentInfo"]["status"] : bookingData["serviceStatus"];

        // Compose the push notification
        const message = {
            notification: {
                title: "New Booking Assigned 🎉",
                body: `A new booking is assigned to you for service on ${serviceDate}. Please check the app for details.`,
            },
            data: {
                type: "booking",
                bookingId: bookingId,
                screen: "BookingDetailsPage",
            },
            android: {
                notification: {
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
            token: fcmToken,
        };


        const response = await admin.messaging().send(message);
        console.log(`Notification sent to ${maidName} for booking ${bookingId} ${response.successCount} notifications sent.`);
    } catch (error) {
        console.error("Error sending notification:", error);
    }

    return null;
});



