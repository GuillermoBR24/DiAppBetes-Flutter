package com.diappbetes.backend.controller;

import com.diappbetes.backend.dto.*;
import com.diappbetes.backend.service.AuthService;
import com.google.firebase.auth.FirebaseToken;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // Se llama justo después de que Flutter haga createUserWithEmailAndPassword
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        try {
            FirebaseToken token = authService.verifyToken(req.getIdToken());
            authService.createProfile(token, req.getUsername(), req.getBirthDate());
            return ResponseEntity.ok(Map.of("status", "ok"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    // Se llama ANTES de hacer signInWithEmailAndPassword, si el usuario
    // escribió un username en vez de un email
    @GetMapping("/resolve-email")
    public ResponseEntity<?> resolveEmail(@RequestParam String username) {
        try {
            String email = authService.resolveEmailByUsername(username);
            return ResponseEntity.ok(new ResolveEmailResponse(email));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "USER_NOT_FOUND"));
        }
    }

    // Se llama justo después de que Flutter haga signInWithEmailAndPassword
    @PostMapping("/login-confirm")
    public ResponseEntity<?> loginConfirm(@Valid @RequestBody LoginConfirmRequest req) {
        try {
            FirebaseToken token = authService.verifyToken(req.getIdToken());
            Map<String, Object> profile = authService.confirmLogin(token);
            return ResponseEntity.ok(profile);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}