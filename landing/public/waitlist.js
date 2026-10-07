// Waitlist form → Firestore collection `waitlist` (create-only, see
// riung/firestore.rules). Firebase config comes from Hosting's reserved
// /__/firebase/init.json, so no keys live in this repo. If the project has
// no Web app registered yet, the form says so honestly instead of
// pretending the email was saved.
const SDK = 'https://www.gstatic.com/firebasejs/10.12.2';
const form = document.getElementById('waitlist-form');
const status = document.getElementById('form-status');
const button = form.querySelector('button');
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

let dbPromise;
function getDb() {
  dbPromise ??= (async () => {
    const res = await fetch('/__/firebase/init.json');
    if (!res.ok) throw new Error('no-config');
    const config = await res.json();
    const { initializeApp } = await import(`${SDK}/firebase-app.js`);
    const fs = await import(`${SDK}/firebase-firestore.js`);
    return { fs, db: fs.getFirestore(initializeApp(config)) };
  })();
  return dbPromise;
}

function show(msg, kind) {
  status.textContent = msg;
  status.className = 'form-status' + (kind ? ' ' + kind : '');
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = form.email.value.trim().toLowerCase();
  if (!EMAIL.test(email)) {
    show('Please enter a valid email address.', 'err');
    form.email.focus();
    return;
  }
  button.disabled = true;
  show('Saving…');
  try {
    const { fs, db } = await getDb();
    await fs.addDoc(fs.collection(db, 'waitlist'), {
      email,
      lang: 'en',
      source: 'landing',
      createdAt: fs.serverTimestamp(),
    });
    form.reset();
    show("You're on the list. We'll email you when Riung is on Google Play.", 'ok');
  } catch (err) {
    console.error(err);
    dbPromise = undefined;
    show("Sorry, we couldn't save your email right now. Please try again later.", 'err');
  } finally {
    button.disabled = false;
  }
});
