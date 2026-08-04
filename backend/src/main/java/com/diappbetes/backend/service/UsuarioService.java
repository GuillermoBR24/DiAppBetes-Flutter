package com.diappbetes.backend.service;

import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;

@Service
public class UsuarioService {

    public void guardarUsuario(String id, Map<String, Object> data) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        db.collection("usuarios").document(id).set(data).get();
    }

    public Map<String, Object> obtenerUsuario(String id) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        DocumentSnapshot doc = db.collection("usuarios").document(id).get().get();
        return doc.exists() ? doc.getData() : null;
    }
}