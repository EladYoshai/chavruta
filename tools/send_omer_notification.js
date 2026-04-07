// ============================================
// Omer Notification Sender - Location-Aware
// ============================================
//
// This script checks each user's location, calculates
// their local צאת הכוכבים (nightfall), and sends the
// omer reminder at the right time.
//
// Run this every 15 minutes via cron:
// */15 * * * * node /path/to/send_omer_notification.js
//
// SETUP:
// 1. npm install firebase-admin suncalc
// 2. Place serviceAccountKey.json in this directory
// ============================================

const admin = require('firebase-admin');
const SunCalc = require('suncalc');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'chavroota-6c454',
});

const db = admin.firestore();

// Omer season check (Nisan 16 - Sivan 5)
function isOmerSeason() {
  // Simple check: roughly mid-April to early June
  const now = new Date();
  const month = now.getMonth() + 1; // 1-12
  const day = now.getDate();
  // Approximate: April 5 to June 15
  if (month === 4 && day >= 5) return true;
  if (month === 5) return true;
  if (month === 6 && day <= 15) return true;
  return false;
}

// Calculate צאת הכוכבים (nightfall) for a location
// Approximately 25-40 minutes after sunset
function getNightfall(lat, lon, date) {
  const times = SunCalc.getTimes(date, lat, lon);
  const sunset = times.sunset;
  // צאת הכוכבים ≈ sunset + 30 minutes (3 medium stars visible)
  const nightfall = new Date(sunset.getTime() + 30 * 60 * 1000);
  return nightfall;
}

async function sendOmerNotifications() {
  if (!isOmerSeason()) {
    console.log('Not omer season. Exiting.');
    return;
  }

  const now = new Date();
  console.log(`Checking omer notifications at ${now.toISOString()}`);

  // Get all users
  const usersSnap = await db.collection('users').get();
  const tokensSnap = await db.collection('push_tokens').get();

  const tokenMap = {};
  tokensSnap.forEach(doc => {
    if (doc.data().token) tokenMap[doc.id] = doc.data().token;
  });

  let sent = 0, skipped = 0;

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    const token = tokenMap[userDoc.id];

    // Skip if no token or user disabled omer reminders
    if (!token) { skipped++; continue; }
    if (user.omerReminderPush === false) { skipped++; continue; }

    // Get user's location (default to Jerusalem)
    const lat = user.latitude || 31.7683;
    const lon = user.longitude || 35.2137;

    // Calculate nightfall for user's location
    const nightfall = getNightfall(lat, lon, now);

    // Check if we're within the notification window
    // (nightfall to nightfall + 15 minutes)
    const diffMinutes = (now - nightfall) / (1000 * 60);

    if (diffMinutes >= 0 && diffMinutes <= 15) {
      // It's time! Check if we already sent today
      const sentKey = `omer_sent_${userDoc.id}_${now.toISOString().substring(0, 10)}`;

      try {
        const sentDoc = await db.collection('notification_log').doc(sentKey).get();
        if (sentDoc.exists) {
          skipped++;
          continue; // Already sent today
        }

        // Send notification
        const message = {
          notification: {
            title: 'חברותא - ספירת העומר 🌾',
            body: 'הגיע הזמן לספור ספירת העומר!',
          },
          webpush: {
            notification: {
              icon: '/icons/Icon-192.png',
              dir: 'rtl',
              lang: 'he',
              tag: 'chavruta-omer',
              renotify: true,
              actions: [
                { action: 'omer_done', title: 'קראתי, תודה ✓' },
                { action: 'omer_snooze', title: 'תזכיר עוד 30 דקות' },
              ],
            },
          },
          token: token,
        };

        await admin.messaging().send(message);
        sent++;

        // Log that we sent
        await db.collection('notification_log').doc(sentKey).set({
          sent: true,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        const sunsetStr = getNightfall(lat, lon, now).toLocaleTimeString('he-IL');
        console.log(`✅ Sent to ${user.userName || userDoc.id} (nightfall: ${sunsetStr})`);

      } catch (err) {
        console.error(`❌ Failed for ${userDoc.id}:`, err.message);
        skipped++;
      }
    } else {
      skipped++;
      if (diffMinutes < 0) {
        // Not yet nightfall for this user
      }
    }
  }

  console.log(`\nDone: ${sent} sent, ${skipped} skipped`);
}

sendOmerNotifications();
