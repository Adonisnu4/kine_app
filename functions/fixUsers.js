const admin = require("firebase-admin");
const serviceAccount = require("./keys/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://kine-8c247.firebaseio.com"
});

async function fixAllUsers() {
  const db = admin.firestore();

  const snapshot = await db.collection("usuarios").get();
  console.log(`Usuarios encontrados: ${snapshot.size}`);

  for (const doc of snapshot.docs) {
    await doc.ref.set(
      {
        deviceTokens: [],
      },
      { merge: true }
    );

    console.log(`✔️ Usuario actualizado: ${doc.id}`);
  }

  console.log("🎉 Todos los usuarios fueron actualizados.");
  process.exit();
}

fixAllUsers();
