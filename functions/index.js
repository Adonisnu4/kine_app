// --- Importaciones modernas (Functions v2 + Admin SDK) ---
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");

// --- Inicializar Firebase ---
initializeApp();
const db = getFirestore();

// --- Función principal ---
exports.updateUserPlanOnSubscription = onDocumentWritten(
  {
    document: "customers/{userId}/subscriptions/{subscriptionId}",
    region: "us-central1", // Cambia si tu proyecto usa otra región
  },
  async (event) => {
    try {
      const afterData = event.data.after?.data();
      const beforeData = event.data.before?.data();

      // ⚠️ Si el documento fue eliminado, salimos.
      if (!afterData) {
        console.log("🗑️ Suscripción eliminada, no se actualiza el plan.");
        return null;
      }

      const userId = event.params.userId;
      const status = afterData.status;
      const userRef = db.collection("usuarios").doc(userId);

      // Evita ejecutar si no hay cambios en el estado.
      if (beforeData && beforeData.status === afterData.status) {
        console.log(`⏸️ Estado sin cambios para ${userId}: ${status}`);
        return null;
      }

      console.log(`🔄 Cambio detectado para usuario ${userId} → Estado: ${status}`);

      // === CASO 1: Suscripción activa o en prueba ===
      if (status === "active" || status === "trialing") {
        const premiumData = {
          plan: "pro",
          isPro: true,
          perfilDestacado: true,
          limitePacientes: 9999,
        };

        await userRef.update(premiumData);
        console.log(`✅ Usuario ${userId} actualizado a plan PRO.`);

      // === CASO 2: Suscripción cancelada o vencida ===
      } else if (["canceled", "unpaid", "incomplete_expired"].includes(status)) {
        const standardData = {
          plan: "estandar",
          isPro: false,
          perfilDestacado: false,
          limitePacientes: 50,
        };

        await userRef.update(standardData);
        console.log(`⚠️ Usuario ${userId} revertido a plan ESTÁNDAR.`);
      }

      return null;
    } catch (error) {
      console.error("❌ Error en updateUserPlanOnSubscription:", error);
      return null;
    }
  }
);