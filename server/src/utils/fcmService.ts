// /src/services/fcmService.ts
import admin from '../config/firebase';  // Import the initialized Firebase Admin SDK

interface NotificationMessage {
  title: string;
  body: string;
  data:any
}

interface DataMessage {
  [key: string]: string; // Dynamic object for data-only messages
}

// Function to send a notification to a single device
export const sendNotificationToDevice = async (deviceToken: string, message: NotificationMessage) => {
  const { title, body,data } = message;

  const messagePayload = {
    notification: {
      title: title,
      body: body,
    },
    token: deviceToken,
    data:data
  };

  try {
    const response = await admin.messaging().send(messagePayload);
    console.log('Successfully sent notification:', response);
    return response;
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
};

// Function to send a notification to multiple devices
export const sendNotificationToMultipleDevices = async (deviceTokens: string[], message: NotificationMessage) => {
  const { title, body } = message;

  const messagePayload = {
    notification: {
      title: title,
      body: body,
    },
    tokens: deviceTokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(messagePayload);
    console.log(`${response.successCount} notifications sent successfully`);
    return response;
  } catch (error) {
    console.error('Error sending notifications:', error);
    throw error;
  }
};

// Function to send data-only message (no notification shown to the user)
export const sendDataMessage = async (deviceToken: string, data: DataMessage) => {
  const messagePayload = {
    data: data,  // Data-only message (no visible notification)
    token: deviceToken,
  };

  try {
    const response = await admin.messaging().send(messagePayload);
    console.log('Successfully sent data message:', response);
    return response;
  } catch (error) {
    console.error('Error sending data message:', error);
    throw error;
  }
};
