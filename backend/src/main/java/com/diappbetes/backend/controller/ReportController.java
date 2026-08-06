package com.diappbetes.backend.controller;

import com.diappbetes.backend.dto.ReportRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private static final String FORMSUBMIT_URL =
            "https://formsubmit.co/ajax/diappbetes0@gmail.com";

    private final RestTemplate restTemplate = new RestTemplate();

    // Esta ruta queda protegida automáticamente por el FirebaseTokenFilter,
    // ya que no empieza por /api/auth/**
    @PostMapping
    public ResponseEntity<?> sendReport(@Valid @RequestBody ReportRequest req,
                                         Authentication authentication) {
        String uid = (String) authentication.getPrincipal();

        Map<String, Object> body = Map.of(
                "_subject", "[" + req.getType() + "] " + req.getTitle(),
                "Tipo", req.getType(),
                "Título", req.getTitle(),
                "Descripción", req.getDescription(),
                "UID", uid
        );

        try {
            restTemplate.postForEntity(FORMSUBMIT_URL, body, String.class);
            return ResponseEntity.ok(Map.of("status", "ok"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body(Map.of("error", "No se pudo enviar el reporte"));
        }
    }
}