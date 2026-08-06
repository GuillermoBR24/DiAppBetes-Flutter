package com.diappbetes.backend.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();

        // Los endpoints de auth ya son públicos vía SecurityConfig,
        // así que no hace falta verificar token ahí.
        if (path.startsWith("/api/auth/")) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response); // deja que Security responda 401 más abajo
            return;
        }

        String idToken = authHeader.substring(7);

        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);

            // Guardamos el uid autenticado en el contexto de Spring Security.
            // Los controladores podrán acceder a él vía SecurityContextHolder
            // o inyectando "Authentication" en el método.
            UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                    decodedToken.getUid(), // principal = uid
                    null,
                    Collections.emptyList() // sin roles por ahora
            );
            auth.setDetails(decodedToken); // por si necesitas email, emailVerified, etc.

            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception e) {
            // Token inválido o expirado: no seteamos autenticación,
            // Spring Security devolverá 401 automáticamente.
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}