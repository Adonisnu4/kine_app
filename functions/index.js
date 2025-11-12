/**
 * ============================================================
 * 🔔 CLOUD FUNCTIONS - UN KINE AMIGO
 * Compatible con Firebase Functions v2
 * ============================================================
 */

const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializar Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// === CONFIGURACIÓN GENERAL ===
const REGION = "northamerica-northeast1"; // nam5 //
const TIMEZONE = "America/Santiago"; // 🇨🇱 Zona horaria de Chile

/**
 * ============================================================
 * 📬 HELPER: Enviar notificaciones a múltiples tokens
 * ============================================================
 */
async function sendToTokens(tokens, notification, data = {}) {
  const valid = (tokens || []).filter(Boolean);
  if (!valid.length) {
    logger.warn("⚠️ No hay tokens válidos para enviar notificación.");
    return;
  }

  const payload = {
    tokens: valid,
    notification,
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(payload);
    logger.info(`📤 Notificación enviada a ${response.successCount} dispositivos`);
  } catch (err) {
    logger.error("❌ Error al enviar notificación FCM:", err);
  }
}

/**
 * ============================================================
 * 🩺 1️⃣ NUEVA CITA → Notifica al kinesiólogo
 * ============================================================
 */
exports.notifyNewAppointment = onDocumentCreated(
  { region: REGION, document: "citas/{citaId}" },
  async (event) => {
    const cita = event.data.data();
    if (!cita || !cita.kineId) return;

    const kineDoc = await db.collection("usuarios").doc(cita.kineId).get();
    const tokens = kineDoc.data()?.deviceTokens || [];

    await sendToTokens(
      tokens,
      {
        title: "📅 Nueva solicitud de cita",
        body: `${cita.pacienteNombre || "Un paciente"} ha solicitado una cita.`,
      },
      {
        type: "cita",
        citaId: event.params.citaId,
        pacienteId: cita.pacienteId || "",
      }
    );

    logger.info(`📢 Nueva cita notificada al kinesiólogo ${cita.kineId}`);
  }
);

/**
 * ============================================================
 * 💬 2️⃣ NUEVO MENSAJE → Notifica al receptor
 * ============================================================
 */
exports.notifyNewMessage = onDocumentCreated(
  { region: REGION, document: "chats/{chatId}/messages/{messageId}" },
  async (event) => {
    const msg = event.data.data();
    if (!msg || !msg.receiverId) {
      logger.warn("⚠️ Mensaje sin receiverId, se omite.");
      return;
    }

    try {
      const receptorDoc = await db.collection("usuarios").doc(msg.receiverId).get();
      const tokens = receptorDoc.data()?.deviceTokens || [];

      if (!tokens.length) {
        logger.warn(`⚠️ Usuario ${msg.receiverId} sin tokens registrados.`);
        return;
      }

      const texto = (msg.content || msg.texto || "").toString();
      const preview = texto.slice(0, 60);

      await sendToTokens(
        tokens,
        {
          title: "💬 Nuevo mensaje",
          body: `${msg.senderName || "Alguien"}: ${preview}${texto.length > 60 ? "..." : ""}`,
        },
        {
          type: "mensaje",
          chatWith: msg.senderId || "",
          chatId: event.params.chatId,
        }
      );

      logger.info(`📨 Notificación enviada a ${msg.receiverId}`);
    } catch (err) {
      logger.error("❌ Error enviando notificación de mensaje:", err);
    }
  }
);

/**
 * ============================================================
 * ✅❌ 3️⃣ CAMBIO DE ESTADO DE CITA → Notifica al paciente
 * ============================================================
 */
exports.notifyCitaStatusChange = onDocumentUpdated(
  { region: REGION, document: "citas/{citaId}" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after || before.estado === after.estado) return;

    const pacienteId = after.pacienteId;
    const kineNombre = after.kineNombre || "tu kinesiólogo";
    const nuevoEstado = after.estado;

    let mensaje = "";
    // 🚀 --- ¡CAMBIO CRÍTICO AQUÍ! (Usando MAYÚSCULAS) ---
    if (nuevoEstado === "ACEPTADA" || nuevoEstado === "CONFIRMADA") {
      mensaje = `Tu cita con ${kineNombre} fue aceptada ✅`;
    } else if (nuevoEstado === "DENEGADA" || nuevoEstado === "RECHAZADA") {
      mensaje = `Tu cita con ${kineNombre} fue rechazada ❌`;
    } else if (nuevoEstado === "CANCELADA") {
      mensaje = `Tu cita con ${kineNombre} ha sido cancelada.`;
    } else {
      return; // No notifica en 'completada' u otros estados
    }
    // 🚀 --- FIN DEL CAMBIO ---

    try {
      const pacienteDoc = await db.collection("usuarios").doc(pacienteId).get();
      const tokens = pacienteDoc.data()?.deviceTokens || [];

      await sendToTokens(
        tokens,
        {
          title: "📅 Estado de tu cita",
          body: mensaje,
        },
        {
          type: "cita_estado",
          citaId: event.params.citaId,
          estado: nuevoEstado,
        }
      );

      logger.info(`📢 Notificación enviada al paciente ${pacienteId}`);
    } catch (err) {
      logger.error("❌ Error enviando notificación de cita:", err);
    }
  }
);

/**
 * ============================================================
 * 💳 4️⃣ STRIPE - Actualiza plan de usuario
 * ============================================================
 */
exports.updateUserPlanOnSubscription = onDocumentWritten(
  { region: "us-central1", document: "customers/{userId}/subscriptions/{subscriptionId}" },
  async (event) => {
    try {
      const afterData = event.data.after?.data();
      const beforeData = event.data.before?.data();

      if (!afterData) {
        logger.info("🗑️ Suscripción eliminada, sin acción.");
        return;
      }

      const userId = event.params.userId;
      const status = afterData.status;
      const userRef = db.collection("usuarios").doc(userId);

      if (beforeData && beforeData.status === afterData.status) return;

      if (status === "active" || status === "trialing") {
        await userRef.update({
          plan: "pro",
          isPro: true,
          perfilDestacado: true,
          limitePacientes: 9999,
        });
        logger.info(`✅ Usuario ${userId} actualizado a plan PRO.`);
      } else if (["canceled", "unpaid", "incomplete_expired"].includes(status)) {
        await userRef.update({
          plan: "estandar",
          isPro: false,
          perfilDestacado: false,
          limitePacientes: 50,
        });
        logger.info(`⚠️ Usuario ${userId} revertido a plan ESTÁNDAR.`);
      }
    } catch (error) {
      logger.error("❌ Error en updateUserPlanOnSubscription:", error);
    }
  }
);

/**
 * ============================================================
 * ⏰ 5️⃣ TAREA PROGRAMADA - Cancela citas expiradas
 * ============================================================
 */
exports.cancelarCitasExpiradas = onSchedule(
  {
    schedule: "every 1 hours", // Se ejecuta cada hora
    region: REGION,
    timeZone: TIMEZONE,
  },
  async (event) => {
    logger.info("⏰ Ejecutando la función para cancelar citas expiradas...");

    const ahora = admin.firestore.Timestamp.now();

    const citasPendientesRef = db.collection("citas");
    const snapshot = await citasPendientesRef
      // 🚀 --- ¡CAMBIO CRÍTICO AQUÍ! (Usando MAYÚSCULAS) ---
      .where("estado", "==", "PENDIENTE")
      .where("fechaCita", "<", ahora)
      .get();

    if (snapshot.empty) {
      logger.info("👍 No se encontraron citas 'PENDIENTE' para cancelar.");
      return null;
    }

    const batch = db.batch();

    snapshot.forEach(doc => {
      logger.warn(`⏳ Cancelando cita expirada: ${doc.id}`);
      const citaRef = db.collection("citas").doc(doc.id);
      batch.update(citaRef, {
        // 🚀 --- ¡CAMBIO CRÍTICO AQUÍ! (Usando MAYÚSCULAS) ---
        estado: "CANCELADA",
        motivoCancelacion: "Expiró por falta de confirmación."
      });
    });

    await batch.commit();

    logger.info(`✅ Se cancelaron automáticamente ${snapshot.size} citas.`);
    return null;
  }
);