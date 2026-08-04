package com.diappbetes.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.util.Base64;

@Configuration
public class FirebaseConfig {

    @Value("${FIREBASE_CREDENTIALS_BASE64:}")
    private String firebaseCredentialsBase64;

    @PostConstruct
    public void init() throws Exception {
        InputStream serviceAccount;

        if (firebaseCredentialsBase64 != null && !firebaseCredentialsBase64.isBlank()) {
            byte[] decoded = Base64.getDecoder().decode(firebaseCredentialsBase64);
            serviceAccount = new ByteArrayInputStream(decoded);
        } else {
            // Fallback para desarrollo local
            serviceAccount = getClass().getClassLoader()
                    .getResourceAsStream("serviceAccountKey.json");
        }

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(options);
        }
    }
}