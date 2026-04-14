// ============================================
// Scheduler: picks notification type by Israel local time
// Invoked by GitHub Actions every 30 minutes.
// ============================================

const { sendByType } = require('./send_notification.js');

function israelHourMinute() {
  // Runs in TZ=Asia/Jerusalem (set by workflow env). Fall back to Intl otherwise.
  const now = new Date();
  const fmt = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Jerusalem',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  const parts = fmt.formatToParts(now);
  const hour = parseInt(parts.find(p => p.type === 'hour').value, 10);
  const minute = parseInt(parts.find(p => p.type === 'minute').value, 10);
  return { hour, minute };
}

function weekday() {
  // 0 = Sunday ... 6 = Saturday (Israel TZ)
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Jerusalem',
    weekday: 'short',
  });
  const short = fmt.format(new Date());
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(short);
}

async function main() {
  const forced = (process.env.FORCE_TYPE || '').trim();
  if (forced) {
    console.log(`Forced type: ${forced}`);
    await sendByType(forced);
    return;
  }

  const { hour, minute } = israelHourMinute();
  const wd = weekday();
  console.log(`Israel time: ${hour}:${String(minute).padStart(2, '0')}, weekday=${wd}`);

  // Slots (runs every 30 min, so only one slot fires per call):
  //   07:30 - morning encouragement (medium) for all active users, skip Saturday
  //   13:00 - quiet midday nudge (low) only for people who opted in to high freq
  //   20:00 - streak-in-danger warning, skip Friday/Saturday evening
  //   20:30 - encouragement for users who haven't completed their goal today (high tier only)
  if (minute < 30) {
    // First half of hour
    if (hour === 7 && wd !== 6) return sendByType('encouragement_medium');
    if (hour === 13 && wd !== 6) return sendByType('encouragement_low');
    if (hour === 20 && wd !== 5 && wd !== 6) return sendByType('streak');
  } else {
    // Second half
    if (hour === 20 && wd !== 5 && wd !== 6) return sendByType('encouragement_high');
  }

  console.log('No notification slot matched this run. Exiting.');
}

main().catch(err => {
  console.error('Scheduler failed:', err);
  process.exit(1);
});
