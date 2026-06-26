package com.diappbetes.services;

import com.google.cloud.firestore.*;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class AuthService {
    public Map<String, Object> verifyAndGetProfile(String uid)
            throws FirebaseAuthException, ExecutionException, InterruptedException {

        UserRecord user = FirebaseAuth.getInstance().getUser(uid);

        if (!user.isEmailVerified()) {
            throw new IllegalStateException("email-not-verified");
        }

        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot profile = db.collection("profiles")
                .document(uid)
                .get()
                .get();

        if (!profile.exists()) {
            throw new IllegalStateException("profile-not-found");
        }

        DocumentSnapshot config = db.collection("app_config")
                .document("global")
                .get()
                .get();

        if (config.exists()) {
            Boolean maintenance = config.getBoolean("maintenance_mode");
            String maintenanceMsg = config.getString("maintenance_message");
            if (Boolean.TRUE.equals(maintenance)) {
                Map<String, Object> result = new HashMap<>();
                result.put("maintenance", true);
                result.put("maintenanceMessage",
                    maintenanceMsg != null ? maintenanceMsg : "App en mantenimiento");
                return result;
            }
        }

        Map<String, Object> data = profile.getData();
        Map<String, Object> result = new HashMap<>();
        result.put("maintenance", false);
        result.put("uid", uid);
        result.put("email", user.getEmail());
        result.put("username", data.get("username"));
        result.put("role", data.get("role"));
        result.put("fsi", data.get("fsi"));

        return result;
    }

    public String resolveEmailFromUsername(String username)
            throws ExecutionException, InterruptedException {

        Firestore db = FirestoreClient.getFirestore();
        List<QueryDocumentSnapshot> docs = db.collection("profiles")
                .whereEqualTo("username", username.toLowerCase())
                .limit(1)
                .get()
                .get()
                .getDocuments();

        if (docs.isEmpty()) {
            throw new IllegalArgumentException("user-not-found");
        }

        return (String) docs.get(0).getData().get("email");
    }

    public String generateCustomToken(String uid) throws FirebaseAuthException {
        return FirebaseAuth.getInstance().createCustomToken(uid);
    }
}