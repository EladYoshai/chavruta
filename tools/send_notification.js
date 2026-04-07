// ============================================
// Backend: Send Push Notification via FCM
// ============================================
//
// SETUP:
// 1. Install: npm install firebase-admin
// 2. Download your Firebase service account key:
//    Firebase Console → Project Settings → Service Accounts → Generate New Private Key
// 3. Save it as 'serviceAccountKey.json' in this directory
// 4. Run: node send_notification.js
//
// This script sends a push notification to ALL saved tokens,
// or to a specific token.
// ============================================

const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
// REPLACE with your service account key file path
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'chavroota-6c454',
});

const db = admin.firestore();

// ============================================
// Send notification to a SPECIFIC token
// ============================================
async function sendToToken(token, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    webpush: {
      notification: {
        icon: '/icons/Icon-192.png',
        dir: 'rtl',
        lang: 'he',
        badge: '/icons/Icon-192.png',
      },
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent:', response);
    return response;
  } catch (error) {
    console.error('❌ Error sending:', error.message);
    return null;
  }
}

// ============================================
// Send notification to ALL saved tokens
// ============================================
async function sendToAll(title, body) {
  try {
    // Get all tokens from Firestore
    const snapshot = await db.collection('push_tokens').get();

    if (snapshot.empty) {
      console.log('No tokens found in database');
      return;
    }

    console.log(`Found ${snapshot.size} tokens. Sending...`);

    const tokens = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (data.token) {
        tokens.push(data.token);
      }
    });

    // Send to each token
    let success = 0;
    let failed = 0;
    for (const token of tokens) {
      const result = await sendToToken(token, title, body);
      if (result) success++;
      else failed++;
    }

    console.log(`\nDone: ${success} sent, ${failed} failed, ${tokens.length} total`);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

// ============================================
// Example: Send a notification
// ============================================

// Change these to your desired notification content:
const TITLE = 'חברותא';
const BODY = 'הגיע הזמן ללמוד תורה! 📖';

// Send to all users:
sendToAll(TITLE, BODY);

// Or send to a specific token:
// sendToToken('USER_FCM_TOKEN_HERE', TITLE, BODY);
