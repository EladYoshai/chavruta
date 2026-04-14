// ============================================
// Backend: Send Push Notifications via FCM
// ============================================
//
// SETUP:
// 1. npm install firebase-admin
// 2. Download service account key from Firebase Console
//    → Project Settings → Service Accounts → Generate New Private Key
// 3. Save as 'serviceAccountKey.json' in this directory
// 4. Run: node send_notification.js [type]
//
// Types: omer, streak, meat_dairy, encouragement, custom
// ============================================

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'chavroota-6c454',
});

const db = admin.firestore();

// ============================================
// Notification templates
// ============================================

const notifications = {
  omer: {
    title: 'חברותא - ספירת העומר 🌾',
    body: 'לא לשכוח לספור ספירת העומר הלילה!',
    actions: [
      { action: 'omer_done', title: 'קראתי, תודה ✓' },
      { action: 'omer_snooze', title: 'תזכיר לי עוד 30 דקות' },
    ],
  },
  streak: {
    title: 'חברותא - הרצף שלך בסכנה! 🔥',
    body: 'עוד לא למדת היום. אל תשבור את הרצף!',
  },
  meat_dairy: {
    title: 'חברותא - אתה חלבי! 🥛',
    body: 'עבר הזמן הנדרש, אתה יכול לאכול חלבי.',
  },
  encouragement_low: {
    title: 'חברותא 📖',
    body: 'יום טוב ללמוד תורה!',
  },
  encouragement_medium: {
    title: 'חברותא - המשך כך! 💪',
    body: 'כל יום של לימוד מקרב את הגאולה. בוא ללמוד!',
  },
  encouragement_high: {
    title: 'חברותא - שלום! 🌟',
    body: '"גדול תלמוד תורה יותר מהצלת נפשות" (מגילה טז:). הגיע הזמן ללמוד!',
  },
};

// ============================================
// Send to a specific token
// ============================================
async function sendToToken(token, title, body, actions) {
  const message = {
    notification: { title, body },
    webpush: {
      notification: {
        icon: '/chavruta/icons/Icon-192.png',
        badge: '/chavruta/icons/Icon-192.png',
        dir: 'rtl',
        lang: 'he',
        tag: 'chavruta-' + Date.now(),
        renotify: true,
        actions: actions || [],
      },
    },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Sent to', token.substring(0, 20) + '...');
    return true;
  } catch (error) {
    console.error('❌ Failed:', error.message);
    return false;
  }
}

// ============================================
// Send by type to eligible users
// ============================================
async function sendByType(type) {
  const notif = notifications[type];
  if (!notif) {
    console.error('Unknown type:', type);
    return;
  }

  // Get all users with their preferences
  const usersSnap = await db.collection('users').get();
  const tokensSnap = await db.collection('push_tokens').get();

  // Build token map (uid -> token)
  const tokenMap = {};
  tokensSnap.forEach(doc => {
    if (doc.data().token) tokenMap[doc.id] = doc.data().token;
  });

  let sent = 0, skipped = 0;

  for (const userDoc of usersSnap.docs) {
    const user = userDoc.data();
    const token = tokenMap[userDoc.id];
    if (!token) { skipped++; continue; }

    // Check user preferences
    if (type === 'omer' && user.omerReminderPush === false) { skipped++; continue; }
    if (type === 'streak' && user.streakReminderPush === false) { skipped++; continue; }
    if (type === 'meat_dairy' && user.meatDairyReminderPush === false) { skipped++; continue; }
    if (type.startsWith('encouragement')) {
      const level = user.encouragementLevel || 'medium';
      if (level === 'none') { skipped++; continue; }
      // Match level to notification type
      const typeLevel = type.replace('encouragement_', '');
      const levels = ['low', 'medium', 'high'];
      if (levels.indexOf(typeLevel) > levels.indexOf(level)) { skipped++; continue; }
    }

    const ok = await sendToToken(token, notif.title, notif.body, notif.actions);
    if (ok) sent++; else skipped++;
  }

  console.log(`\n${type}: ${sent} sent, ${skipped} skipped`);
}

// ============================================
// Send custom notification to all
// ============================================
async function sendCustom(title, body) {
  const tokensSnap = await db.collection('push_tokens').get();
  let sent = 0;
  for (const doc of tokensSnap.docs) {
    const token = doc.data().token;
    if (token) {
      const ok = await sendToToken(token, title, body);
      if (ok) sent++;
    }
  }
  console.log(`Custom: ${sent} sent`);
}

// ============================================
// Main - run from command line (only if invoked directly)
// ============================================
if (require.main === module) {
  const type = process.argv[2] || 'encouragement_medium';

  if (type === 'custom') {
    const title = process.argv[3] || 'חברותא';
    const body = process.argv[4] || 'הודעה חדשה';
    sendCustom(title, body);
  } else {
    sendByType(type);
  }
}

module.exports = { sendByType, sendCustom, notifications };

// Usage examples:
// node send_notification.js omer
// node send_notification.js streak
// node send_notification.js meat_dairy
// node send_notification.js encouragement_low
// node send_notification.js encouragement_medium
// node send_notification.js encouragement_high
// node send_notification.js custom "כותרת" "תוכן ההודעה"
