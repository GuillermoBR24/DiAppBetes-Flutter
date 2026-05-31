import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (equivalentes a las CSS variables de Ionic)
  static const Color azulFondo = Color.fromRGBO(26, 58, 110, 1);       // --azul-fondo
  static const Color blanco = Color(0xFFFFFFFF);           // --blanco
  static const Color grisDivider = Color(0xFFE0E0E0);      // --gris-divider
  static const Color grisTexto = Color(0xFF666666);        // --gris-texto
  static const Color verdesuave = Color(0xFF4CAF50);       // --verde-suave
  static const Color ambarSuave = Color(0xFFFFA726);       // --ambar-suave
  static const Color rojoSuave = Color(0xFFEF5350);        // --rojo-suave
  static const Color fondoAzulClaroActivo = Color(0xFF42A5F5); // activo tab
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color progressBg = Color(0xFFDDDDDD);

  static const Color cenaFondo = Color(0x66DCA7E6);
  static const Color cenaTexto = Color(0xFF7B1FA2);

  static const Color desayunoFondo = Color(0x33FF8000);
  static const Color desayunoTexto = Color(0xFFFF6D00);

  static const Color almuerzoFondo = Color(0x3395BF40);
  static const Color almuerzoTexto = Color(0xFF689F38); 

  static const Color comidaFondo = Color(0x335299E0);
  static const Color comidaTexto = Color(0xFF1976D2);

  static const Color meriendaFondo = Color(0x33B81466);
  static const Color meriendaTexto = Color(0xFFAD1457);

  static const Color frutasFondo = Color(0x33FF8A66);   // #ff8a6633
  static const Color frutasTexto = Color(0xFFE64A19);   // #E64A19
  
  static const Color carnesFondo = Color(0x33E05252);   // #e0525233
  static const Color carnesTexto = Color(0xFFD32F2F);   // #D32F2F
  
  static const Color pescadosFondo = Color(0x335299E0); // #5299e033
  static const Color pescadosTexto = Color(0xFF1976D2); // #1976D2
  
  static const Color mariscosFondo = Color(0x3326D9BB); // #26d9bb33
  static const Color mariscosTexto = Color(0xFF00796B); // #00796B
  
  static const Color verdurasFondo = Color(0x3340BF40); // #40bf4033
  static const Color verdurasTexto = Color(0xFF388E3C); // #388E3C
  
  static const Color lacteosFondo = Color(0x336633CC);  // #6633cc33
  static const Color lacteosTexto = Color(0xFF512DA8);  // #512DA8
  
  static const Color cerealesFondo = Color(0x33FF9933); // #ff993333
  static const Color cerealesTexto = Color(0xFFF57C00); // #F57C00
  
  static const Color bolleriaFondo = Color(0x33B81466); // #b8146633
  static const Color bolleriaTexto = Color(0xFFAD1457); // #AD1457
  
  static const Color dulcesFondo = Color(0x33FF8000);   // #ff800033
  static const Color dulcesTexto = Color(0xFFFF6D00);   // #FF6D00
  
  static const Color bebidasFondo = Color(0x330DA6F2);  // #0da6f233
  static const Color bebidasTexto = Color(0xFF0288D1);  // #0288D1
  
  static const Color legumbresFondo = Color(0x3395BF40); // #95bf4033
  static const Color legumbresTexto = Color(0xFF689F38); // #689F38
  
  static const Color frutosSecosFondo = Color(0x33CCCC33); // #cccc3333
  static const Color frutosSecosTexto = Color(0xFFAFB42B); // #AFB42B
  
  static const Color platoFondo = Color(0x33B233CC);    // #b233cc33
  static const Color platoTexto = Color(0xFF7B1FA2);    // #7B1FA2
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulFondo,
          primary: AppColors.azulFondo,
          background: AppColors.blanco,
        ),
        scaffoldBackgroundColor: AppColors.blanco,
        fontFamily: 'Roboto',
      );
}