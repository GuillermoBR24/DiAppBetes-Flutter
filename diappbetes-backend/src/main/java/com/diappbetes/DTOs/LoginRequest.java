package com.diappbetes.DTOs;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "El identificador es obligatorio")
    private String identifier;   // email o username

    @NotBlank(message = "La contraseña es obligatoria")
    private String password;
}
