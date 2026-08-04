package com.diappbetes.backend.service;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class AuthService {

    private Firestore db() {
        return FirestoreClient.getFirestore();
    }

    /** Verifica el idToken de Firebase y devuelve el uid + email + emailVerified */
    public FirebaseToken verifyToken(String idToken) throws Exception {
        return FirebaseAuth.getInstance().verifyIdToken(idToken);
    }

    /** Crea el documento de perfil tras el registro. Los valores sensibles
     *  (role, fsi) los fija el servidor, NUNCA el cliente. */
    public void createProfile(FirebaseToken token, String username, String birthDate)
            throws ExecutionException, InterruptedException {

        String uid = token.getUid();
        String email = token.getEmail();
        String resolvedUsername = (username == null || username.isBlank())
                ? email.split("@")[0]
                : username;

        Map<String, Object> profile = new HashMap<>();
        profile.put("id", uid);
        profile.put("username", resolvedUsername);
        profile.put("username_lower", resolvedUsername.toLowerCase());
        profile.put("email", email);
        profile.put("birth_date", (birthDate == null || birthDate.isBlank()) ? null : birthDate);
        profile.put("role", "Usuario");           // fijo, el cliente no puede cambiarlo
        profile.put("fsi", 50.0);                 // fijo, el cliente no puede cambiarlo
        profile.put("avatar_base64", null);
        profile.put("email_verified", false);
        profile.put("created_at", com.google.cloud.firestore.FieldValue.serverTimestamp());
        profile.put("updated_at", com.google.cloud.firestore.FieldValue.serverTimestamp());

        db().collection("profiles").document(uid).set(profile).get();
    }

    /** Resuelve username -> email para que el cliente pueda hacer signIn */
    public String resolveEmailByUsername(String username) throws ExecutionException, InterruptedException {
        String usernameLower = username.trim().toLowerCase();

        QuerySnapshot query = db().collection("profiles")
                .whereEqualTo("username_lower", usernameLower)
                .limit(1)
                .get()
                .get();

        List<QueryDocumentSnapshot> docs = query.getDocuments();
        if (docs.isEmpty()) {
            throw new RuntimeException("USER_NOT_FOUND");
        }

        return (String) docs.get(0).getData().get("email");
    }

    /** Tras un login exitoso en el cliente, confirma y sincroniza el estado
     *  emailVerified en Firestore, y devuelve el perfil. */
    public Map<String, Object> confirmLogin(FirebaseToken token)
            throws ExecutionException, InterruptedException {

        String uid = token.getUid();
        boolean emailVerified = token.isEmailVerified();

        if (!emailVerified) {
            throw new RuntimeException("EMAIL_NOT_VERIFIED");
        }

        DocumentSnapshot doc = db().collection("profiles").document(uid).get().get();
        if (!doc.exists()) {
            throw new RuntimeException("PROFILE_NOT_FOUND");
        }

        db().collection("profiles").document(uid).update(
                Map.of(
                        "email_verified", true,
                        "updated_at", com.google.cloud.firestore.FieldValue.serverTimestamp()
                )
        ).get();

        return doc.getData();
    }
}