package com.diappbetes.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class LoginConfirmRequest {
    @NotBlank
    private String idToken; // token tras el signIn exitoso en Firebase Auth (cliente)

    public String getIdToken() { return idToken; }
    public void setIdToken(String idToken) { this.idToken = idToken; }
}