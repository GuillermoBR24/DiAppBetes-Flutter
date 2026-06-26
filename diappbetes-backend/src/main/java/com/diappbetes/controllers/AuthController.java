package com.diappbetes.controllers;

import com.diappbetes.DTOs.ApiResponse;
import com.diappbetes.DTOs.LoginRequest;
import com.diappbetes.services.AuthService;
import com.google.firebase.auth.FirebaseAuthException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/resolve-email")
    public ResponseEntity<ApiResponse<Map<String, String>>> resolveEmail(
            @RequestBody @Valid LoginRequest request) {
        try {
            String identifier = request.getIdentifier();

            if (identifier.contains("@")) {
                return ResponseEntity.ok(
                    ApiResponse.ok("Email directo", Map.of("email", identifier))
                );
            }

            String email = authService.resolveEmailFromUsername(identifier);
            return ResponseEntity.ok(
                ApiResponse.ok("Email resuelto", Map.of("email", email))
            );

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Usuario no encontrado"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error interno: " + e.getMessage()));
        }
    }

    /**
     * POST /api/v1/auth/verify-session
     * Flutter envía el UID tras hacer login con Firebase Auth.
     * El backend verifica email, estado, mantenimiento y devuelve el perfil.
     * Body: { "identifier": "<uid_firebase>" }  (reutilizamos el DTO)
     */
    @PostMapping("/verify-session")
    public ResponseEntity<ApiResponse<Map<String, Object>>> verifySession(
            @RequestBody Map<String, String> body) {
        try {
            String uid = body.get("uid");

            if (uid == null || uid.isBlank()) {
                return ResponseEntity.badRequest()
                        .body(ApiResponse.error("UID requerido"));
            }

            Map<String, Object> result = authService.verifyAndGetProfile(uid);

            // Si está en mantenimiento
            if (Boolean.TRUE.equals(result.get("maintenance"))) {
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                        .body(ApiResponse.error(
                            (String) result.get("maintenanceMessage")
                        ));
            }

            return ResponseEntity.ok(ApiResponse.ok("Sesión verificada", result));

        } catch (IllegalStateException e) {
            String code = e.getMessage();
            if ("email-not-verified".equals(code)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.error("Email no verificado"));
            }
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error("Perfil no encontrado"));
        } catch (FirebaseAuthException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.error("Usuario no válido en Firebase"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Error: " + e.getMessage()));
        }
    }
}