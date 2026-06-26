package com.diappbetes.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class ApiKeyFilter implements Filter {

    @Value("${api.secret-key}")
    private String validApiKey;

    private static final String[] PUBLIC_PATHS = {"/actuator/health"};

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;

        String path = req.getRequestURI();

        for (String pub : PUBLIC_PATHS) {
            if (path.startsWith(pub)) {
                chain.doFilter(request, response);
                return;
            }
        }

        String apiKey = req.getHeader("X-API-Key");

        if (apiKey == null || !apiKey.equals(validApiKey)) {
            res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"API key inválida\"}");
            return;
        }

        chain.doFilter(request, response);
    }
}