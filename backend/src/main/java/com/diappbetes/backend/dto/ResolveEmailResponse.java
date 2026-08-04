package com.diappbetes.backend.dto;

public class ResolveEmailResponse {
    private String email;
    public ResolveEmailResponse(String email) { this.email = email; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
}