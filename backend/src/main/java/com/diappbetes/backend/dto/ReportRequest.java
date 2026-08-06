package com.diappbetes.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class ReportRequest {
    @NotBlank private String type;
    @NotBlank private String title;
    @NotBlank private String description;

    // getters y setters
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}