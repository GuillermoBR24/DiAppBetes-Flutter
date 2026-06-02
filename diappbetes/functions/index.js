// functions/index.js
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function para eliminar un usuario (llamada desde el admin)
 * Solo administradores pueden ejecutarla
 */
exports.deleteUserByAdmin = onCall(async (request) => {
  // 1. Verificar que hay un usuario autenticado
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes estar autenticado");
  }

  const adminUid = request.auth.uid;
  const targetUid = request.data.uid;

  if (!targetUid) {
    throw new HttpsError("invalid-argument", "UID del usuario es requerido");
  }

  // 2. Verificar que el usuario que llama es admin
  const adminProfile = await admin.firestore()
      .collection("profiles")
      .doc(adminUid)
      .get();

  const role = (adminProfile.data()?.role || "").toLowerCase();
  if (role !== "administrador" && role !== "admin") {
    throw new HttpsError("permission-denied", "Solo administradores pueden eliminar usuarios");
  }

  // 3. No permitir que el admin se elimine a sí mismo por esta vía
  if (adminUid === targetUid) {
    throw new HttpsError("invalid-argument", "No puedes eliminarte a ti mismo desde el panel admin");
  }

  try {
    // 4. Eliminar el usuario de Firebase Auth
    await admin.auth().deleteUser(targetUid);
    console.log(`✅ Usuario ${targetUid} eliminado de Firebase Auth por admin ${adminUid}`);
    return { success: true, uid: targetUid };
  } catch (error) {
    // Si el usuario ya no existe en Auth, continuar (no es error crítico)
    if (error.code === "auth/user-not-found") {
      console.log(`⚠️ Usuario ${targetUid} no existe en Auth, continuando...`);
      return { success: true, uid: targetUid, warning: "Usuario no existía en Auth" };
    }
    console.error(`❌ Error eliminando usuario ${targetUid}:`, error);
    throw new HttpsError("internal", `Error al eliminar usuario: ${error.message}`);
  }
});