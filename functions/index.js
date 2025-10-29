// Usamos la sintaxis de importación moderna para las funciones de 2ª generación (Gen 2)
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

// Inicializa la app de Firebase
initializeApp();

const db = getFirestore(); // Obtener la referencia a Firestore

// 1. La función se activa con cualquier CAMBIO en la subcolección de suscripciones de Stripe
// Utilizamos 'onDocumentUpdated' de Gen 2
exports.updateUserPlanOnSubscription = onDocumentUpdated(
    {
        document: 'customers/{userId}/subscriptions/{subscriptionId}',
        // Puedes establecer una región si lo deseas, por defecto es us-central1
        // region: 'southamerica-east1', 
    }, 
    async (event) => {
        
        // Verifica que haya datos de suscripción después del cambio
        const afterData = event.data.after.data();
        if (!afterData) {
            console.log("No hay datos después del evento.");
            return null;
        }

        const userId = event.params.userId;
        const status = afterData.status;

        // --- Referencia a la colección 'usuarios' ---
        const userRef = db.collection('usuarios').doc(userId);

        // --- Caso: Suscripción Activa (Pago exitoso) o en Prueba ---
        if (status === 'active' || status === 'trialing') {
            
            const premiumData = {
                plan: 'premium',
                perfilDestacado: true,
                limitePacientes: 9999, 
                // Asegúrate de que los nombres de los campos coincidan con tu RegisterScreen
            };
            
            try {
                await userRef.update(premiumData);
                console.log(`✅ Usuario ${userId} actualizado a plan premium.`);
            } catch (error) {
                console.error(`❌ Error al actualizar el usuario ${userId} a premium:`, error);
            }

        // --- Caso: Suscripción Cancelada, Vencida o sin pagar ---
        } else if (status === 'canceled' || status === 'unpaid' || status === 'incomplete_expired') {
            
            const standardData = {
                plan: 'estandar',
                perfilDestacado: false,
                limitePacientes: 50,
            };
            
            try {
                await userRef.update(standardData);
                console.log(`⚠️ Usuario ${userId} revertido a plan estándar.`);
            } catch (error) {
                console.warn(`Error al revertir el usuario ${userId}:`, error);
            }
        }
        
        return null;
    }
);