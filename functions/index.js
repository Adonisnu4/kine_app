/**
 * ============================================================
 * CLOUD FUNCTIONS - UN KINE AMIGO
 * Compatible con Firebase Functions v2
 * ============================================================
 */

// IMPORTANTE: ESTA LÍNEA FALTABA
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { 
  onDocumentCreated, 
  onDocumentUpdated, 
  onDocumentWritten 
} = require("firebase-functions/v2/firestore");

const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// Inicializar Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
// === CONFIGURACIÓN GENERAL ===
const REGION = "northamerica-northeast1"; 
const TIMEZONE = "America/Santiago"; 

/**
 * ============================================================
 * HELPER: Enviar notificaciones a múltiples tokens
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
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
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
 *  NUEVA CITA → Notifica al kinesiólogo
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
  }
);

/**
 * ============================================================
 * NUEVO MENSAJE → Notifica al receptor
 * ============================================================
 */
exports.notifyNewMessage = onDocumentCreated(
  { region: REGION, document: "chats/{chatId}/messages/{messageId}" },
  async (event) => {
    const msg = event.data.data();
    if (!msg || !msg.receiverId) return;

    try {
      const receptorDoc = await db.collection("usuarios").doc(msg.receiverId).get();
      const tokens = receptorDoc.data()?.deviceTokens || [];

      if (!tokens.length) return;

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
    } catch (err) {
      logger.error("❌ Error enviando notificación de mensaje:", err);
    }
  }
);

/**
 * ============================================================
 * CAMBIO DE ESTADO DE CITA → Notifica al paciente
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
    if (nuevoEstado === "aceptada") {
      mensaje = `Tu cita con ${kineNombre} fue aceptada ✅`;
    } else if (nuevoEstado === "rechazada") {
      mensaje = `Tu cita con ${kineNombre} fue rechazada ❌`;
    } else {
      return;
    }

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
    } catch (err) {
      logger.error("❌ Error enviando notificación de cita:", err);
    }
  }
);

/**
 * ============================================================
 * STRIPE - Actualiza plan del usuario
 * ============================================================
 */
exports.updateUserPlanOnSubscription = onDocumentWritten(
  { region: "us-central1", document: "customers/{userId}/subscriptions/{subscriptionId}" },
  async (event) => {
    try {
      const afterData = event.data.after?.data();
      const beforeData = event.data.before?.data();

      if (!afterData) return;

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
      } else {
        await userRef.update({
          plan: "estandar",
          isPro: false,
          perfilDestacado: false,
          limitePacientes: 50,
        });
      }
    } catch (error) {
      logger.error("❌ Error en updateUserPlanOnSubscription:", error);
    }
  }
);

/**
 * ============================================================
 * CANCELAR AUTOMÁTICAMENTE CITAS VENCIDAS
 * ============================================================
 */
exports.autoCancelOldAppointments = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "America/Santiago",
    region: REGION,
  },
  async () => {
    const now = new Date();

    const snapshot = await db
      .collection("citas")
      .where("estado", "==", "pendiente")
      .get();

    const batch = db.batch();

    snapshot.forEach((doc) => {
      const data = doc.data();
      const fechaCita = data.fechaCita?.toDate();

      if (fechaCita && fechaCita < now) {
        console.log(`Cancelando cita vencida: ${doc.id}`);
        batch.update(doc.ref, { estado: "cancelada" });
      }
    });

    await batch.commit();
    console.log("✔ Citas vencidas actualizadas automáticamente");
    return null;
  }
);