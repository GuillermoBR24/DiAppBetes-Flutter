// ---------------------------------------------------------------------------
// Modelo Food — equivalente a la interfaz Food de Angular
// ---------------------------------------------------------------------------
class Food {
  final String id;
  final String name;
  final String category;
  final double carbsPer100g;
  final double caloriesPer100g;
  final String? iconUrl;
  final bool? containsGluten;
  final bool isCustom; // ← NUEVO: true si es un alimento personal del usuario

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    this.iconUrl,
    this.containsGluten,
    this.isCustom = false,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'plato',
      carbsPer100g: (map['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      caloriesPer100g: (map['calories_per_100g'] as num?)?.toDouble() ?? 0,
      iconUrl: map['icon_url']?.toString(),
      containsGluten: map['contains_gluten'] as bool?,
      isCustom: map['is_custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'carbs_per_100g': carbsPer100g,
    'calories_per_100g': caloriesPer100g,
    'icon_url': iconUrl,
    'contains_gluten': containsGluten,
    'is_custom': isCustom,
  };

  Food copyWith({
    String? name,
    String? category,
    double? carbsPer100g,
    double? caloriesPer100g,
    bool? containsGluten,
  }) => Food(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    carbsPer100g: carbsPer100g ?? this.carbsPer100g,
    caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
    iconUrl: iconUrl,
    containsGluten: containsGluten ?? this.containsGluten,
    isCustom: isCustom,
  );
}

// ---------------------------------------------------------------------------
// FoodService — catálogo genérico local (sin marcas)
//
// La búsqueda por texto SOLO consulta este catálogo curado a mano: nombres
// genéricos como "Pasta", "Pollo", "Manzana"... con valores nutricionales
// estándar (referencia BEDCA/USDA), para que el usuario encuentre rápido
// lo que cocina en casa sin tener que lidiar con decenas de marcas.
//
// Los productos envasados concretos (con su marca y dato exacto del
// envase) se obtienen aparte, escaneando el código de barras desde
// AddFoodModal, que consulta OpenFoodFacts directamente — ese flujo no
// pasa por este servicio.
// ---------------------------------------------------------------------------
class FoodService {
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;
  FoodService._internal();

  // ── Búsqueda por texto — solo sobre el catálogo genérico local ────────── //
  // Síncrona y al instante: no hay llamada de red ni loading.
  List<Food> searchFoods(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getLocalFoods();

    return _localFoods.where((f) {
      final name = f.name.toLowerCase();
      final cat  = f.category.toLowerCase();
      // Coincidencia por nombre completo o por cualquier palabra del nombre
      // (p.ej. "espagueti" debe encontrar "Espaguetis", "pollo" debe
      // encontrar "Pechuga de pollo").
      return name.contains(q) ||
          cat.contains(q) ||
          name.split(' ').any((word) => word.startsWith(q));
    }).toList();
  }

  // ── Catálogo genérico completo (se muestra al abrir el modal) ─────────── //
  List<Food> getLocalFoods() => List.unmodifiable(_localFoods);

  // ── Catálogo curado: alimentos genéricos sin marca ─────────────────────── //
  // Valores por 100g. Ampliable según necesidad — esto cubre lo más común
  // del día a día: cereales/pasta/pan, carnes, pescados, lácteos, frutas,
  // verduras, legumbres, frutos secos, dulces/bollería y bebidas básicas.
  static final List<Food> _localFoods = [
    // ── Cereales, pasta, pan ──────────────────────────────────────────── //
    const Food(id: 'g_arroz_blanco',   name: 'Arroz blanco (cocido)',     category: 'cereales', carbsPer100g: 28.0, caloriesPer100g: 130, containsGluten: false),
    const Food(id: 'g_arroz_integral', name: 'Arroz integral (cocido)',   category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 123, containsGluten: false),
    const Food(id: 'g_pasta',          name: 'Pasta / Macarrones (cocida)', category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 131, containsGluten: true),
    const Food(id: 'g_espaguetis',     name: 'Espaguetis (cocidos)',      category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 131, containsGluten: true),
    const Food(id: 'g_pan_blanco',     name: 'Pan blanco',                category: 'cereales', carbsPer100g: 49.0, caloriesPer100g: 265, containsGluten: true),
    const Food(id: 'g_pan_integral',   name: 'Pan integral',              category: 'cereales', carbsPer100g: 41.0, caloriesPer100g: 247, containsGluten: true),
    const Food(id: 'g_avena',          name: 'Avena (copos)',             category: 'cereales', carbsPer100g: 58.7, caloriesPer100g: 372, containsGluten: false),
    const Food(id: 'g_quinoa',         name: 'Quinoa (cocida)',           category: 'cereales', carbsPer100g: 21.0, caloriesPer100g: 120, containsGluten: false),
    const Food(id: 'g_cuscus',         name: 'Cuscús (cocido)',           category: 'cereales', carbsPer100g: 23.0, caloriesPer100g: 112, containsGluten: true),
    const Food(id: 'g_maiz',           name: 'Maíz dulce',                category: 'cereales', carbsPer100g: 19.0, caloriesPer100g: 96,  containsGluten: false),

    // ── Carnes y huevo ────────────────────────────────────────────────── //
    const Food(id: 'g_pollo',          name: 'Pechuga de pollo',          category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 165, containsGluten: false),
    const Food(id: 'g_pavo',           name: 'Pechuga de pavo',           category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 135, containsGluten: false),
    const Food(id: 'g_ternera',        name: 'Ternera magra',             category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 158, containsGluten: false),
    const Food(id: 'g_cerdo',          name: 'Lomo de cerdo',             category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 143, containsGluten: false),
    const Food(id: 'g_jamon_serrano',  name: 'Jamón serrano',             category: 'carnes', carbsPer100g: 0.4, caloriesPer100g: 241, containsGluten: false),
    const Food(id: 'g_jamon_york',     name: 'Jamón cocido (york)',       category: 'carnes', carbsPer100g: 1.5, caloriesPer100g: 113, containsGluten: false),
    const Food(id: 'g_huevo',          name: 'Huevo',                     category: 'carnes', carbsPer100g: 0.6, caloriesPer100g: 155, containsGluten: false),

    // ── Pescados y mariscos ───────────────────────────────────────────── //
    const Food(id: 'g_salmon',         name: 'Salmón',                    category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 208, containsGluten: false),
    const Food(id: 'g_merluza',        name: 'Merluza',                   category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 82,  containsGluten: false),
    const Food(id: 'g_atun_fresco',    name: 'Atún (fresco)',             category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 130, containsGluten: false),
    const Food(id: 'g_atun_lata',      name: 'Atún en lata (al natural)', category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 116, containsGluten: false),
    const Food(id: 'g_bacalao',        name: 'Bacalao',                   category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 82,  containsGluten: false),
    const Food(id: 'g_gambas',         name: 'Gambas',                    category: 'mariscos', carbsPer100g: 0.0, caloriesPer100g: 85,  containsGluten: false),
    const Food(id: 'g_mejillones',     name: 'Mejillones',                category: 'mariscos', carbsPer100g: 7.0, caloriesPer100g: 86,  containsGluten: false),

    // ── Lácteos ───────────────────────────────────────────────────────── //
    const Food(id: 'g_leche_entera',   name: 'Leche entera',              category: 'lacteos', carbsPer100g: 4.8, caloriesPer100g: 61,  containsGluten: false),
    const Food(id: 'g_leche_desnatada',name: 'Leche desnatada',           category: 'lacteos', carbsPer100g: 5.0, caloriesPer100g: 35,  containsGluten: false),
    const Food(id: 'g_yogur_natural',  name: 'Yogur natural',             category: 'lacteos', carbsPer100g: 3.6, caloriesPer100g: 59,  containsGluten: false),
    const Food(id: 'g_yogur_griego',   name: 'Yogur griego',              category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 97,  containsGluten: false),
    const Food(id: 'g_queso_fresco',   name: 'Queso fresco',              category: 'lacteos', carbsPer100g: 3.0, caloriesPer100g: 98,  containsGluten: false),
    const Food(id: 'g_queso_manchego', name: 'Queso manchego/curado',     category: 'lacteos', carbsPer100g: 0.5, caloriesPer100g: 392, containsGluten: false),
    const Food(id: 'g_requeson',       name: 'Requesón',                  category: 'lacteos', carbsPer100g: 3.4, caloriesPer100g: 98,  containsGluten: false),

    // ── Frutas ────────────────────────────────────────────────────────── //
    const Food(id: 'g_manzana',        name: 'Manzana',                   category: 'frutas', carbsPer100g: 14.0, caloriesPer100g: 52, containsGluten: false),
    const Food(id: 'g_platano',        name: 'Plátano',                   category: 'frutas', carbsPer100g: 23.0, caloriesPer100g: 89, containsGluten: false),
    const Food(id: 'g_naranja',        name: 'Naranja',                   category: 'frutas', carbsPer100g: 12.0, caloriesPer100g: 47, containsGluten: false),
    const Food(id: 'g_pera',           name: 'Pera',                      category: 'frutas', carbsPer100g: 15.0, caloriesPer100g: 57, containsGluten: false),
    const Food(id: 'g_fresas',         name: 'Fresas',                    category: 'frutas', carbsPer100g: 7.7,  caloriesPer100g: 32, containsGluten: false),
    const Food(id: 'g_uvas',           name: 'Uvas',                      category: 'frutas', carbsPer100g: 18.0, caloriesPer100g: 69, containsGluten: false),
    const Food(id: 'g_melon',          name: 'Melón',                     category: 'frutas', carbsPer100g: 8.0,  caloriesPer100g: 34, containsGluten: false),
    const Food(id: 'g_sandia',         name: 'Sandía',                    category: 'frutas', carbsPer100g: 8.0,  caloriesPer100g: 30, containsGluten: false),
    const Food(id: 'g_kiwi',           name: 'Kiwi',                      category: 'frutas', carbsPer100g: 15.0, caloriesPer100g: 61, containsGluten: false),

    // ── Verduras ──────────────────────────────────────────────────────── //
    const Food(id: 'g_tomate',         name: 'Tomate',                    category: 'verduras', carbsPer100g: 3.9,  caloriesPer100g: 18,  containsGluten: false),
    const Food(id: 'g_lechuga',        name: 'Lechuga',                   category: 'verduras', carbsPer100g: 2.9,  caloriesPer100g: 15,  containsGluten: false),
    const Food(id: 'g_zanahoria',      name: 'Zanahoria',                 category: 'verduras', carbsPer100g: 10.0, caloriesPer100g: 41,  containsGluten: false),
    const Food(id: 'g_patata',         name: 'Patata (cocida)',           category: 'verduras', carbsPer100g: 17.0, caloriesPer100g: 77,  containsGluten: false),
    const Food(id: 'g_cebolla',        name: 'Cebolla',                   category: 'verduras', carbsPer100g: 9.3,  caloriesPer100g: 40,  containsGluten: false),
    const Food(id: 'g_pepino',         name: 'Pepino',                    category: 'verduras', carbsPer100g: 3.6,  caloriesPer100g: 15,  containsGluten: false),
    const Food(id: 'g_calabacin',      name: 'Calabacín',                 category: 'verduras', carbsPer100g: 3.1,  caloriesPer100g: 17,  containsGluten: false),
    const Food(id: 'g_pimiento',       name: 'Pimiento',                  category: 'verduras', carbsPer100g: 6.0,  caloriesPer100g: 31,  containsGluten: false),
    const Food(id: 'g_brocoli',        name: 'Brócoli',                   category: 'verduras', carbsPer100g: 6.6,  caloriesPer100g: 34,  containsGluten: false),
    const Food(id: 'g_espinacas',      name: 'Espinacas',                 category: 'verduras', carbsPer100g: 3.6,  caloriesPer100g: 23,  containsGluten: false),

    // ── Legumbres ─────────────────────────────────────────────────────── //
    const Food(id: 'g_lentejas',       name: 'Lentejas (cocidas)',        category: 'legumbres', carbsPer100g: 20.0, caloriesPer100g: 116, containsGluten: false),
    const Food(id: 'g_garbanzos',      name: 'Garbanzos (cocidos)',       category: 'legumbres', carbsPer100g: 18.0, caloriesPer100g: 164, containsGluten: false),
    const Food(id: 'g_alubias',        name: 'Alubias / Judías (cocidas)',category: 'legumbres', carbsPer100g: 21.0, caloriesPer100g: 127, containsGluten: false),
    const Food(id: 'g_guisantes',      name: 'Guisantes',                 category: 'legumbres', carbsPer100g: 14.0, caloriesPer100g: 81,  containsGluten: false),

    // ── Frutos secos ──────────────────────────────────────────────────── //
    const Food(id: 'g_almendras',      name: 'Almendras',                 category: 'frutos_secos', carbsPer100g: 22.0, caloriesPer100g: 579, containsGluten: false),
    const Food(id: 'g_nueces',         name: 'Nueces',                    category: 'frutos_secos', carbsPer100g: 14.0, caloriesPer100g: 654, containsGluten: false),
    const Food(id: 'g_cacahuetes',     name: 'Cacahuetes',                category: 'frutos_secos', carbsPer100g: 16.0, caloriesPer100g: 567, containsGluten: false),
    const Food(id: 'g_avellanas',      name: 'Avellanas',                 category: 'frutos_secos', carbsPer100g: 17.0, caloriesPer100g: 628, containsGluten: false),

    // ── Dulces y bollería ─────────────────────────────────────────────── //
    const Food(id: 'g_chocolate_negro',name: 'Chocolate negro 70%',       category: 'dulces',   carbsPer100g: 46.0, caloriesPer100g: 546, containsGluten: false),
    const Food(id: 'g_chocolate_leche',name: 'Chocolate con leche',       category: 'dulces',   carbsPer100g: 56.0, caloriesPer100g: 535, containsGluten: false),
    const Food(id: 'g_miel',           name: 'Miel',                      category: 'dulces',   carbsPer100g: 82.0, caloriesPer100g: 304, containsGluten: false),
    const Food(id: 'g_azucar',         name: 'Azúcar',                    category: 'dulces',   carbsPer100g: 100.0,caloriesPer100g: 387, containsGluten: false),
    const Food(id: 'g_croissant',      name: 'Croissant',                 category: 'bolleria', carbsPer100g: 46.0, caloriesPer100g: 406, containsGluten: true),
    const Food(id: 'g_galletas',       name: 'Galletas (tipo María)',     category: 'bolleria', carbsPer100g: 75.0, caloriesPer100g: 440, containsGluten: true),

    // ── Bebidas ───────────────────────────────────────────────────────── //
    const Food(id: 'g_zumo_naranja',   name: 'Zumo de naranja natural',   category: 'bebidas', carbsPer100g: 10.4, caloriesPer100g: 45, containsGluten: false),
    const Food(id: 'g_refresco_cola',  name: 'Refresco de cola',          category: 'bebidas', carbsPer100g: 10.6, caloriesPer100g: 42, containsGluten: false),
    const Food(id: 'g_cerveza',        name: 'Cerveza',                   category: 'bebidas', carbsPer100g: 3.6,  caloriesPer100g: 43, containsGluten: true),

    // ── Otros / platos genéricos ──────────────────────────────────────── //
    const Food(id: 'g_aceite_oliva',   name: 'Aceite de oliva',           category: 'plato', carbsPer100g: 0.0, caloriesPer100g: 884, containsGluten: false),
    const Food(id: 'g_mantequilla',    name: 'Mantequilla',               category: 'plato', carbsPer100g: 0.1, caloriesPer100g: 717, containsGluten: false),

    // ── Cereales, pasta, pan (ampliado) ────────────────────────────────── //
    const Food(id: 'g_arroz_basmati',  name: 'Arroz basmati (cocido)',    category: 'cereales', carbsPer100g: 27.0, caloriesPer100g: 121, containsGluten: false),
    const Food(id: 'g_arroz_jazmin',   name: 'Arroz jazmín (cocido)',     category: 'cereales', carbsPer100g: 28.0, caloriesPer100g: 130, containsGluten: false),
    const Food(id: 'g_fideos',         name: 'Fideos (cocidos)',          category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 138, containsGluten: true),
    const Food(id: 'g_macarrones',     name: 'Macarrones (cocidos)',      category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 131, containsGluten: true),
    const Food(id: 'g_tallarines',     name: 'Tallarines (cocidos)',      category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 131, containsGluten: true),
    const Food(id: 'g_lasagna',        name: 'Lasaña (pasta, cocida)',    category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 131, containsGluten: true),
    const Food(id: 'g_raviolis',       name: 'Raviolis (rellenos, cocidos)', category: 'cereales', carbsPer100g: 28.0, caloriesPer100g: 175, containsGluten: true),
    const Food(id: 'g_ñoquis',         name: 'Ñoquis de patata (cocidos)',category: 'cereales', carbsPer100g: 22.0, caloriesPer100g: 130, containsGluten: true),
    const Food(id: 'g_fideos_arroz',   name: 'Fideos de arroz (cocidos)', category: 'cereales', carbsPer100g: 25.0, caloriesPer100g: 109, containsGluten: false),
    const Food(id: 'g_pan_centeno',    name: 'Pan de centeno',            category: 'cereales', carbsPer100g: 48.0, caloriesPer100g: 259, containsGluten: true),
    const Food(id: 'g_pan_molde',      name: 'Pan de molde',              category: 'cereales', carbsPer100g: 50.0, caloriesPer100g: 270, containsGluten: true),
    const Food(id: 'g_pan_sin_gluten', name: 'Pan sin gluten',            category: 'cereales', carbsPer100g: 52.0, caloriesPer100g: 260, containsGluten: false),
    const Food(id: 'g_pan_pita',       name: 'Pan de pita',               category: 'cereales', carbsPer100g: 56.0, caloriesPer100g: 275, containsGluten: true),
    const Food(id: 'g_tortita_maiz',   name: 'Tortita de maíz',           category: 'cereales', carbsPer100g: 80.0, caloriesPer100g: 387, containsGluten: false),
    const Food(id: 'g_tortita_arroz',  name: 'Tortita de arroz',          category: 'cereales', carbsPer100g: 81.0, caloriesPer100g: 387, containsGluten: false),
    const Food(id: 'g_tortilla_trigo', name: 'Tortilla de trigo (wrap)',  category: 'cereales', carbsPer100g: 50.0, caloriesPer100g: 310, containsGluten: true),
    const Food(id: 'g_tortilla_maiz',  name: 'Tortilla de maíz (wrap)',   category: 'cereales', carbsPer100g: 45.0, caloriesPer100g: 218, containsGluten: false),
    const Food(id: 'g_cereales_maiz',  name: 'Cereales de maíz (copos)',  category: 'cereales', carbsPer100g: 84.0, caloriesPer100g: 357, containsGluten: false),
    const Food(id: 'g_muesli',         name: 'Muesli',                    category: 'cereales', carbsPer100g: 66.0, caloriesPer100g: 362, containsGluten: true),
    const Food(id: 'g_granola',        name: 'Granola',                   category: 'cereales', carbsPer100g: 60.0, caloriesPer100g: 471, containsGluten: true),
    const Food(id: 'g_polenta',        name: 'Polenta (cocida)',          category: 'cereales', carbsPer100g: 14.0, caloriesPer100g: 70,  containsGluten: false),
    const Food(id: 'g_trigo_sarraceno',name: 'Trigo sarraceno (cocido)',  category: 'cereales', carbsPer100g: 20.0, caloriesPer100g: 92,  containsGluten: false),
    const Food(id: 'g_mijo',           name: 'Mijo (cocido)',             category: 'cereales', carbsPer100g: 23.0, caloriesPer100g: 119, containsGluten: false),
    const Food(id: 'g_bulgur',         name: 'Bulgur (cocido)',           category: 'cereales', carbsPer100g: 19.0, caloriesPer100g: 83,  containsGluten: true),
    const Food(id: 'g_harina_trigo',   name: 'Harina de trigo',           category: 'cereales', carbsPer100g: 76.0, caloriesPer100g: 364, containsGluten: true),
    const Food(id: 'g_harina_maiz',    name: 'Harina de maíz',            category: 'cereales', carbsPer100g: 77.0, caloriesPer100g: 365, containsGluten: false),
    const Food(id: 'g_harina_avena',   name: 'Harina de avena',           category: 'cereales', carbsPer100g: 66.0, caloriesPer100g: 389, containsGluten: false),
    const Food(id: 'g_harina_almendra',name: 'Harina de almendra',        category: 'cereales', carbsPer100g: 21.0, caloriesPer100g: 571, containsGluten: false),
    const Food(id: 'g_pan_hamburguesa',name: 'Pan de hamburguesa',        category: 'cereales', carbsPer100g: 50.0, caloriesPer100g: 280, containsGluten: true),
    const Food(id: 'g_pan_perrito',    name: 'Pan de perrito caliente',   category: 'cereales', carbsPer100g: 50.0, caloriesPer100g: 280, containsGluten: true),
    const Food(id: 'g_picos_pan',      name: 'Picos de pan',              category: 'cereales', carbsPer100g: 72.0, caloriesPer100g: 410, containsGluten: true),
    const Food(id: 'g_breadsticks',    name: 'Colines / Breadsticks',     category: 'cereales', carbsPer100g: 70.0, caloriesPer100g: 408, containsGluten: true),
    const Food(id: 'g_couscous_integral', name: 'Cuscús integral (cocido)', category: 'cereales', carbsPer100g: 21.0, caloriesPer100g: 105, containsGluten: true),

    // ── Carnes y derivados (ampliado) ───────────────────────────────────── //
    const Food(id: 'g_pollo_muslo',    name: 'Muslo de pollo',            category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 172, containsGluten: false),
    const Food(id: 'g_pollo_alitas',   name: 'Alitas de pollo',           category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 203, containsGluten: false),
    const Food(id: 'g_pollo_entero',   name: 'Pollo entero (asado)',      category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 190, containsGluten: false),
    const Food(id: 'g_pato',           name: 'Pato',                      category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 337, containsGluten: false),
    const Food(id: 'g_conejo',         name: 'Conejo',                    category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 173, containsGluten: false),
    const Food(id: 'g_cordero',        name: 'Cordero',                   category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 294, containsGluten: false),
    const Food(id: 'g_ternera_filete', name: 'Filete de ternera',         category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 158, containsGluten: false),
    const Food(id: 'g_solomillo_cerdo',name: 'Solomillo de cerdo',        category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 143, containsGluten: false),
    const Food(id: 'g_costillas_cerdo',name: 'Costillas de cerdo',        category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 277, containsGluten: false),
    const Food(id: 'g_panceta',        name: 'Panceta',                   category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 518, containsGluten: false),
    const Food(id: 'g_bacon',          name: 'Bacon / Beicon',            category: 'carnes', carbsPer100g: 1.4, caloriesPer100g: 541, containsGluten: false),
    const Food(id: 'g_chorizo',        name: 'Chorizo',                   category: 'carnes', carbsPer100g: 1.6, caloriesPer100g: 455, containsGluten: false),
    const Food(id: 'g_salchichon',     name: 'Salchichón',                category: 'carnes', carbsPer100g: 1.0, caloriesPer100g: 380, containsGluten: false),
    const Food(id: 'g_chistorra',      name: 'Chistorra',                 category: 'carnes', carbsPer100g: 1.0, caloriesPer100g: 380, containsGluten: false),
    const Food(id: 'g_morcilla',       name: 'Morcilla',                  category: 'carnes', carbsPer100g: 14.0, caloriesPer100g: 379, containsGluten: false),
    const Food(id: 'g_salchichas',     name: 'Salchichas (frankfurt)',    category: 'carnes', carbsPer100g: 3.0, caloriesPer100g: 290, containsGluten: false),
    const Food(id: 'g_mortadela',      name: 'Mortadela',                 category: 'carnes', carbsPer100g: 3.0, caloriesPer100g: 311, containsGluten: false),
    const Food(id: 'g_paté',           name: 'Paté',                      category: 'carnes', carbsPer100g: 2.0, caloriesPer100g: 319, containsGluten: false),
    const Food(id: 'g_fuet',           name: 'Fuet',                      category: 'carnes', carbsPer100g: 1.0, caloriesPer100g: 459, containsGluten: false),
    const Food(id: 'g_lacon',          name: 'Lacón',                     category: 'carnes', carbsPer100g: 0.5, caloriesPer100g: 150, containsGluten: false),
    const Food(id: 'g_pechuga_pavo_fiambre', name: 'Pechuga de pavo (fiambre)', category: 'carnes', carbsPer100g: 1.5, caloriesPer100g: 95,  containsGluten: false),
    const Food(id: 'g_higado',         name: 'Hígado',                    category: 'carnes', carbsPer100g: 3.9, caloriesPer100g: 135, containsGluten: false),
    const Food(id: 'g_albondigas',     name: 'Albóndigas',                category: 'carnes', carbsPer100g: 5.0, caloriesPer100g: 180, containsGluten: true),
    const Food(id: 'g_hamburguesa_ternera', name: 'Hamburguesa de ternera (cruda)', category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 220, containsGluten: false),
    const Food(id: 'g_carne_picada',   name: 'Carne picada mixta',        category: 'carnes', carbsPer100g: 0.0, caloriesPer100g: 215, containsGluten: false),
    const Food(id: 'g_tofu',           name: 'Tofu',                      category: 'carnes', carbsPer100g: 1.9, caloriesPer100g: 76,  containsGluten: false),
    const Food(id: 'g_tempeh',         name: 'Tempeh',                    category: 'carnes', carbsPer100g: 9.4, caloriesPer100g: 192, containsGluten: false),
    const Food(id: 'g_seitan',         name: 'Seitán',                    category: 'carnes', carbsPer100g: 14.0, caloriesPer100g: 370, containsGluten: true),
    const Food(id: 'g_clara_huevo',    name: 'Clara de huevo',            category: 'carnes', carbsPer100g: 0.7, caloriesPer100g: 52,  containsGluten: false),
    const Food(id: 'g_huevo_codorniz', name: 'Huevo de codorniz',         category: 'carnes', carbsPer100g: 0.4, caloriesPer100g: 158, containsGluten: false),

    // ── Pescados y mariscos (ampliado) ──────────────────────────────────── //
    const Food(id: 'g_salmon_ahumado', name: 'Salmón ahumado',            category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 142, containsGluten: false),
    const Food(id: 'g_atun_aceite',    name: 'Atún en lata (al aceite)',  category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 198, containsGluten: false),
    const Food(id: 'g_dorada',         name: 'Dorada',                    category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 121, containsGluten: false),
    const Food(id: 'g_lubina',         name: 'Lubina',                    category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 97,  containsGluten: false),
    const Food(id: 'g_sardinas',       name: 'Sardinas',                  category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 208, containsGluten: false),
    const Food(id: 'g_sardinas_lata',  name: 'Sardinas en lata (aceite)', category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 208, containsGluten: false),
    const Food(id: 'g_boquerones',     name: 'Boquerones',                category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 131, containsGluten: false),
    const Food(id: 'g_anchoas',        name: 'Anchoas en aceite',         category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 210, containsGluten: false),
    const Food(id: 'g_trucha',         name: 'Trucha',                    category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 119, containsGluten: false),
    const Food(id: 'g_caballa',        name: 'Caballa',                   category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 205, containsGluten: false),
    const Food(id: 'g_rape',           name: 'Rape',                      category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 76,  containsGluten: false),
    const Food(id: 'g_lenguado',       name: 'Lenguado',                  category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 86,  containsGluten: false),
    const Food(id: 'g_pez_espada',     name: 'Pez espada',                category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 121, containsGluten: false),
    const Food(id: 'g_bacalao_salado', name: 'Bacalao salado (desalado)', category: 'pescados', carbsPer100g: 0.0, caloriesPer100g: 82,  containsGluten: false),
    const Food(id: 'g_palitos_cangrejo',name:'Palitos de cangrejo (surimi)',category:'pescados', carbsPer100g: 10.0,caloriesPer100g: 95,  containsGluten: true),
    const Food(id: 'g_calamares',      name: 'Calamares',                 category: 'mariscos', carbsPer100g: 3.1, caloriesPer100g: 92,  containsGluten: false),
    const Food(id: 'g_pulpo',          name: 'Pulpo',                     category: 'mariscos', carbsPer100g: 2.2, caloriesPer100g: 82,  containsGluten: false),
    const Food(id: 'g_sepia',          name: 'Sepia',                     category: 'mariscos', carbsPer100g: 1.0, caloriesPer100g: 79,  containsGluten: false),
    const Food(id: 'g_langostinos',    name: 'Langostinos',               category: 'mariscos', carbsPer100g: 0.9, caloriesPer100g: 99,  containsGluten: false),
    const Food(id: 'g_almejas',        name: 'Almejas',                   category: 'mariscos', carbsPer100g: 2.6, caloriesPer100g: 74,  containsGluten: false),
    const Food(id: 'g_berberechos',    name: 'Berberechos',               category: 'mariscos', carbsPer100g: 2.0, caloriesPer100g: 79,  containsGluten: false),
    const Food(id: 'g_navajas',        name: 'Navajas',                   category: 'mariscos', carbsPer100g: 2.0, caloriesPer100g: 76,  containsGluten: false),
    const Food(id: 'g_vieiras',        name: 'Vieiras',                   category: 'mariscos', carbsPer100g: 2.4, caloriesPer100g: 88,  containsGluten: false),
    const Food(id: 'g_centollo',       name: 'Centollo',                  category: 'mariscos', carbsPer100g: 0.0, caloriesPer100g: 87,  containsGluten: false),
    const Food(id: 'g_percebes',       name: 'Percebes',                  category: 'mariscos', carbsPer100g: 0.0, caloriesPer100g: 81,  containsGluten: false),
    const Food(id: 'g_caviar',         name: 'Caviar',                    category: 'mariscos', carbsPer100g: 4.0, caloriesPer100g: 264, containsGluten: false),

    // ── Lácteos (ampliado) ──────────────────────────────────────────────── //
    const Food(id: 'g_leche_semidesnatada', name: 'Leche semidesnatada',  category: 'lacteos', carbsPer100g: 4.9, caloriesPer100g: 47,  containsGluten: false),
    const Food(id: 'g_leche_avena',    name: 'Bebida de avena',           category: 'lacteos', carbsPer100g: 6.6, caloriesPer100g: 47,  containsGluten: true),
    const Food(id: 'g_leche_soja',     name: 'Bebida de soja',            category: 'lacteos', carbsPer100g: 0.5, caloriesPer100g: 33,  containsGluten: false),
    const Food(id: 'g_leche_almendra', name: 'Bebida de almendra',        category: 'lacteos', carbsPer100g: 0.3, caloriesPer100g: 13,  containsGluten: false),
    const Food(id: 'g_leche_coco',     name: 'Bebida de coco',            category: 'lacteos', carbsPer100g: 0.5, caloriesPer100g: 19,  containsGluten: false),
    const Food(id: 'g_nata_montar',    name: 'Nata para montar',          category: 'lacteos', carbsPer100g: 3.0, caloriesPer100g: 337, containsGluten: false),
    const Food(id: 'g_nata_cocinar',   name: 'Nata para cocinar',         category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 195, containsGluten: false),
    const Food(id: 'g_yogur_azucarado',name: 'Yogur azucarado',           category: 'lacteos', carbsPer100g: 16.0, caloriesPer100g: 95, containsGluten: false),
    const Food(id: 'g_yogur_sabores',  name: 'Yogur de sabores',          category: 'lacteos', carbsPer100g: 18.0, caloriesPer100g: 110,containsGluten: false),
    const Food(id: 'g_yogur_desnatado',name: 'Yogur desnatado',           category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 45,  containsGluten: false),
    const Food(id: 'g_kefir',          name: 'Kéfir',                     category: 'lacteos', carbsPer100g: 4.5, caloriesPer100g: 56,  containsGluten: false),
    const Food(id: 'g_skyr',           name: 'Skyr',                      category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 63,  containsGluten: false),
    const Food(id: 'g_queso_mozzarella', name: 'Queso mozzarella',        category: 'lacteos', carbsPer100g: 2.2, caloriesPer100g: 280, containsGluten: false),
    const Food(id: 'g_queso_parmesano',name: 'Queso parmesano',           category: 'lacteos', carbsPer100g: 3.2, caloriesPer100g: 392, containsGluten: false),
    const Food(id: 'g_queso_brie',     name: 'Queso brie',                category: 'lacteos', carbsPer100g: 0.5, caloriesPer100g: 334, containsGluten: false),
    const Food(id: 'g_queso_cabra',    name: 'Queso de cabra',            category: 'lacteos', carbsPer100g: 0.1, caloriesPer100g: 364, containsGluten: false),
    const Food(id: 'g_queso_feta',     name: 'Queso feta',                category: 'lacteos', carbsPer100g: 4.1, caloriesPer100g: 264, containsGluten: false),
    const Food(id: 'g_queso_burgos',   name: 'Queso de Burgos',           category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 174, containsGluten: false),
    const Food(id: 'g_queso_untar',    name: 'Queso para untar',          category: 'lacteos', carbsPer100g: 4.0, caloriesPer100g: 245, containsGluten: false),
    const Food(id: 'g_queso_rallado',  name: 'Queso rallado',             category: 'lacteos', carbsPer100g: 1.0, caloriesPer100g: 380, containsGluten: false),
    const Food(id: 'g_mantequilla_lactea', name: 'Mantequilla (láctea)',  category: 'lacteos', carbsPer100g: 0.1, caloriesPer100g: 717, containsGluten: false),
    const Food(id: 'g_nata_agria',     name: 'Nata agria (sour cream)',   category: 'lacteos', carbsPer100g: 3.0, caloriesPer100g: 198, containsGluten: false),
    const Food(id: 'g_cuajada',        name: 'Cuajada',                   category: 'lacteos', carbsPer100g: 4.5, caloriesPer100g: 87,  containsGluten: false),
    const Food(id: 'g_flan',           name: 'Flan',                      category: 'lacteos', carbsPer100g: 17.0, caloriesPer100g: 110,containsGluten: false),
    const Food(id: 'g_natillas',       name: 'Natillas',                  category: 'lacteos', carbsPer100g: 16.0, caloriesPer100g: 115,containsGluten: false),

    // ── Frutas (ampliado) ────────────────────────────────────────────────── //
    const Food(id: 'g_mandarina',      name: 'Mandarina',                 category: 'frutas', carbsPer100g: 13.0, caloriesPer100g: 53,  containsGluten: false),
    const Food(id: 'g_pomelo',         name: 'Pomelo',                    category: 'frutas', carbsPer100g: 11.0, caloriesPer100g: 42,  containsGluten: false),
    const Food(id: 'g_limon',          name: 'Limón',                     category: 'frutas', carbsPer100g: 9.3,  caloriesPer100g: 29,  containsGluten: false),
    const Food(id: 'g_lima',           name: 'Lima',                      category: 'frutas', carbsPer100g: 11.0, caloriesPer100g: 30,  containsGluten: false),
    const Food(id: 'g_pina',           name: 'Piña',                      category: 'frutas', carbsPer100g: 13.0, caloriesPer100g: 50,  containsGluten: false),
    const Food(id: 'g_mango',          name: 'Mango',                     category: 'frutas', carbsPer100g: 15.0, caloriesPer100g: 60,  containsGluten: false),
    const Food(id: 'g_papaya',         name: 'Papaya',                    category: 'frutas', carbsPer100g: 11.0, caloriesPer100g: 43,  containsGluten: false),
    const Food(id: 'g_aguacate',       name: 'Aguacate',                  category: 'frutas', carbsPer100g: 8.5,  caloriesPer100g: 160, containsGluten: false),
    const Food(id: 'g_cereza',         name: 'Cereza',                    category: 'frutas', carbsPer100g: 16.0, caloriesPer100g: 63,  containsGluten: false),
    const Food(id: 'g_ciruela',        name: 'Ciruela',                   category: 'frutas', carbsPer100g: 11.0, caloriesPer100g: 46,  containsGluten: false),
    const Food(id: 'g_albaricoque',    name: 'Albaricoque',               category: 'frutas', carbsPer100g: 9.3,  caloriesPer100g: 48,  containsGluten: false),
    const Food(id: 'g_melocoton',      name: 'Melocotón',                 category: 'frutas', carbsPer100g: 9.5,  caloriesPer100g: 39,  containsGluten: false),
    const Food(id: 'g_nectarina',      name: 'Nectarina',                 category: 'frutas', carbsPer100g: 11.0, caloriesPer100g: 44,  containsGluten: false),
    const Food(id: 'g_higo',           name: 'Higo',                      category: 'frutas', carbsPer100g: 19.0, caloriesPer100g: 74,  containsGluten: false),
    const Food(id: 'g_granada',        name: 'Granada',                   category: 'frutas', carbsPer100g: 19.0, caloriesPer100g: 83,  containsGluten: false),
    const Food(id: 'g_caqui',          name: 'Caqui',                     category: 'frutas', carbsPer100g: 18.0, caloriesPer100g: 70,  containsGluten: false),
    const Food(id: 'g_frambuesa',      name: 'Frambuesa',                 category: 'frutas', carbsPer100g: 12.0, caloriesPer100g: 52,  containsGluten: false),
    const Food(id: 'g_arandanos',      name: 'Arándanos',                 category: 'frutas', carbsPer100g: 14.0, caloriesPer100g: 57,  containsGluten: false),
    const Food(id: 'g_mora',           name: 'Mora',                      category: 'frutas', carbsPer100g: 10.0, caloriesPer100g: 43,  containsGluten: false),
    const Food(id: 'g_coco',           name: 'Coco (pulpa)',              category: 'frutas', carbsPer100g: 6.2,  caloriesPer100g: 354, containsGluten: false),
    const Food(id: 'g_dátiles',        name: 'Dátiles',                   category: 'frutas', carbsPer100g: 75.0, caloriesPer100g: 282, containsGluten: false),
    const Food(id: 'g_pasas',          name: 'Pasas',                     category: 'frutas', carbsPer100g: 79.0, caloriesPer100g: 299, containsGluten: false),
    const Food(id: 'g_ciruelas_pasas', name: 'Ciruelas pasas',            category: 'frutas', carbsPer100g: 64.0, caloriesPer100g: 240, containsGluten: false),
    const Food(id: 'g_orejones',       name: 'Orejones (albaricoque seco)', category: 'frutas', carbsPer100g: 63.0, caloriesPer100g: 241, containsGluten: false),
    const Food(id: 'g_higos_secos',    name: 'Higos secos',               category: 'frutas', carbsPer100g: 64.0, caloriesPer100g: 249, containsGluten: false),
    const Food(id: 'g_chirimoya',      name: 'Chirimoya',                 category: 'frutas', carbsPer100g: 18.0, caloriesPer100g: 75,  containsGluten: false),
    const Food(id: 'g_maracuya',       name: 'Maracuyá / Fruta de la pasión', category: 'frutas', carbsPer100g: 23.0, caloriesPer100g: 97, containsGluten: false),
    const Food(id: 'g_litchi',         name: 'Lichi',                     category: 'frutas', carbsPer100g: 17.0, caloriesPer100g: 66,  containsGluten: false),
    const Food(id: 'g_membrillo',      name: 'Membrillo',                 category: 'frutas', carbsPer100g: 15.0, caloriesPer100g: 57,  containsGluten: false),
    const Food(id: 'g_carambola',      name: 'Carambola',                 category: 'frutas', carbsPer100g: 6.7,  caloriesPer100g: 31,  containsGluten: false),

    // ── Verduras (ampliado) ──────────────────────────────────────────────── //
    const Food(id: 'g_berenjena',      name: 'Berenjena',                 category: 'verduras', carbsPer100g: 5.9,  caloriesPer100g: 25,  containsGluten: false),
    const Food(id: 'g_coliflor',       name: 'Coliflor',                  category: 'verduras', carbsPer100g: 5.0,  caloriesPer100g: 25,  containsGluten: false),
    const Food(id: 'g_col',            name: 'Col / Repollo',             category: 'verduras', carbsPer100g: 5.8,  caloriesPer100g: 25,  containsGluten: false),
    const Food(id: 'g_coles_bruselas', name: 'Coles de Bruselas',         category: 'verduras', carbsPer100g: 9.0,  caloriesPer100g: 43,  containsGluten: false),
    const Food(id: 'g_apio',           name: 'Apio',                      category: 'verduras', carbsPer100g: 3.0,  caloriesPer100g: 16,  containsGluten: false),
    const Food(id: 'g_puerro',         name: 'Puerro',                    category: 'verduras', carbsPer100g: 14.0, caloriesPer100g: 61,  containsGluten: false),
    const Food(id: 'g_ajo',            name: 'Ajo',                       category: 'verduras', carbsPer100g: 33.0, caloriesPer100g: 149, containsGluten: false),
    const Food(id: 'g_esparragos',     name: 'Espárragos',                category: 'verduras', carbsPer100g: 3.9,  caloriesPer100g: 20,  containsGluten: false),
    const Food(id: 'g_alcachofa',      name: 'Alcachofa',                 category: 'verduras', carbsPer100g: 11.0, caloriesPer100g: 47,  containsGluten: false),
    const Food(id: 'g_remolacha',      name: 'Remolacha',                 category: 'verduras', carbsPer100g: 10.0, caloriesPer100g: 43,  containsGluten: false),
    const Food(id: 'g_rabano',         name: 'Rábano',                    category: 'verduras', carbsPer100g: 3.4,  caloriesPer100g: 16,  containsGluten: false),
    const Food(id: 'g_nabo',           name: 'Nabo',                      category: 'verduras', carbsPer100g: 6.4,  caloriesPer100g: 28,  containsGluten: false),
    const Food(id: 'g_acelga',         name: 'Acelga',                    category: 'verduras', carbsPer100g: 3.7,  caloriesPer100g: 19,  containsGluten: false),
    const Food(id: 'g_endivia',        name: 'Endivia',                   category: 'verduras', carbsPer100g: 4.0,  caloriesPer100g: 17,  containsGluten: false),
    const Food(id: 'g_canonigos',      name: 'Canónigos',                 category: 'verduras', carbsPer100g: 3.6,  caloriesPer100g: 21,  containsGluten: false),
    const Food(id: 'g_rucula',         name: 'Rúcula',                    category: 'verduras', carbsPer100g: 3.7,  caloriesPer100g: 25,  containsGluten: false),
    const Food(id: 'g_champinones',    name: 'Champiñones',               category: 'verduras', carbsPer100g: 3.3,  caloriesPer100g: 22,  containsGluten: false),
    const Food(id: 'g_setas',          name: 'Setas',                     category: 'verduras', carbsPer100g: 4.0,  caloriesPer100g: 28,  containsGluten: false),
    const Food(id: 'g_boletus',        name: 'Boletus',                   category: 'verduras', carbsPer100g: 3.0,  caloriesPer100g: 26,  containsGluten: false),
    const Food(id: 'g_calabaza',       name: 'Calabaza',                  category: 'verduras', carbsPer100g: 6.5,  caloriesPer100g: 26,  containsGluten: false),
    const Food(id: 'g_boniato',        name: 'Boniato / Batata',          category: 'verduras', carbsPer100g: 20.0, caloriesPer100g: 86,  containsGluten: false),
    const Food(id: 'g_jengibre',       name: 'Jengibre',                  category: 'verduras', carbsPer100g: 18.0, caloriesPer100g: 80,  containsGluten: false),
    const Food(id: 'g_judias_verdes',  name: 'Judías verdes',             category: 'verduras', carbsPer100g: 7.0,  caloriesPer100g: 31,  containsGluten: false),
    const Food(id: 'g_okra',           name: 'Okra',                      category: 'verduras', carbsPer100g: 7.5,  caloriesPer100g: 33,  containsGluten: false),
    const Food(id: 'g_chile',          name: 'Chile / Guindilla',         category: 'verduras', carbsPer100g: 8.8,  caloriesPer100g: 40,  containsGluten: false),
    const Food(id: 'g_pimiento_piquillo', name: 'Pimiento del piquillo (asado)', category: 'verduras', carbsPer100g: 5.0, caloriesPer100g: 27, containsGluten: false),
    const Food(id: 'g_tomate_frito',   name: 'Tomate frito',              category: 'verduras', carbsPer100g: 9.0,  caloriesPer100g: 60,  containsGluten: false),
    const Food(id: 'g_salsa_tomate',   name: 'Salsa de tomate (natural)', category: 'verduras', carbsPer100g: 7.0,  caloriesPer100g: 35,  containsGluten: false),
    const Food(id: 'g_kimchi',         name: 'Kimchi',                    category: 'verduras', carbsPer100g: 2.4,  caloriesPer100g: 15,  containsGluten: false),
    const Food(id: 'g_chucrut',        name: 'Chucrut',                   category: 'verduras', carbsPer100g: 4.3,  caloriesPer100g: 19,  containsGluten: false),
    const Food(id: 'g_pepinillo',      name: 'Pepinillo encurtido',       category: 'verduras', carbsPer100g: 2.3,  caloriesPer100g: 11,  containsGluten: false),
    const Food(id: 'g_aceitunas',      name: 'Aceitunas',                 category: 'verduras', carbsPer100g: 4.0,  caloriesPer100g: 145, containsGluten: false),

    // ── Legumbres (ampliado) ─────────────────────────────────────────────── //
    const Food(id: 'g_habas',          name: 'Habas (cocidas)',           category: 'legumbres', carbsPer100g: 18.0, caloriesPer100g: 110, containsGluten: false),
    const Food(id: 'g_soja',           name: 'Soja (cocida)',             category: 'legumbres', carbsPer100g: 9.9,  caloriesPer100g: 173, containsGluten: false),
    const Food(id: 'g_edamame',        name: 'Edamame (cocido)',          category: 'legumbres', carbsPer100g: 8.9,  caloriesPer100g: 122, containsGluten: false),
    const Food(id: 'g_lentejas_rojas', name: 'Lentejas rojas (cocidas)',  category: 'legumbres', carbsPer100g: 20.0, caloriesPer100g: 116, containsGluten: false),
    const Food(id: 'g_alubias_blancas',name: 'Alubias blancas (cocidas)', category: 'legumbres', carbsPer100g: 21.0, caloriesPer100g: 127, containsGluten: false),
    const Food(id: 'g_alubias_negras', name: 'Alubias negras (cocidas)',  category: 'legumbres', carbsPer100g: 24.0, caloriesPer100g: 132, containsGluten: false),
    const Food(id: 'g_alubias_pintas', name: 'Alubias pintas (cocidas)',  category: 'legumbres', carbsPer100g: 22.0, caloriesPer100g: 130, containsGluten: false),
    const Food(id: 'g_hummus',         name: 'Hummus',                    category: 'legumbres', carbsPer100g: 14.0, caloriesPer100g: 166, containsGluten: false),

    // ── Frutos secos y semillas (ampliado) ──────────────────────────────── //
    const Food(id: 'g_pistachos',      name: 'Pistachos',                 category: 'frutos_secos', carbsPer100g: 28.0, caloriesPer100g: 562, containsGluten: false),
    const Food(id: 'g_anacardos',      name: 'Anacardos',                 category: 'frutos_secos', carbsPer100g: 30.0, caloriesPer100g: 553, containsGluten: false),
    const Food(id: 'g_pipas_girasol',  name: 'Pipas de girasol',          category: 'frutos_secos', carbsPer100g: 20.0, caloriesPer100g: 584, containsGluten: false),
    const Food(id: 'g_pipas_calabaza', name: 'Pipas de calabaza',         category: 'frutos_secos', carbsPer100g: 11.0, caloriesPer100g: 559, containsGluten: false),
    const Food(id: 'g_semillas_chia',  name: 'Semillas de chía',          category: 'frutos_secos', carbsPer100g: 42.0, caloriesPer100g: 486, containsGluten: false),
    const Food(id: 'g_semillas_lino',  name: 'Semillas de lino',          category: 'frutos_secos', carbsPer100g: 29.0, caloriesPer100g: 534, containsGluten: false),
    const Food(id: 'g_semillas_sesamo',name: 'Semillas de sésamo',        category: 'frutos_secos', carbsPer100g: 23.0, caloriesPer100g: 573, containsGluten: false),
    const Food(id: 'g_pinones',        name: 'Piñones',                   category: 'frutos_secos', carbsPer100g: 13.0, caloriesPer100g: 673, containsGluten: false),
    const Food(id: 'g_nuez_macadamia', name: 'Nuez de macadamia',         category: 'frutos_secos', carbsPer100g: 14.0, caloriesPer100g: 718, containsGluten: false),
    const Food(id: 'g_nuez_brasil',    name: 'Nuez de Brasil',            category: 'frutos_secos', carbsPer100g: 12.0, caloriesPer100g: 656, containsGluten: false),
    const Food(id: 'g_castañas',       name: 'Castañas',                  category: 'frutos_secos', carbsPer100g: 45.0, caloriesPer100g: 213, containsGluten: false),
    const Food(id: 'g_mantequilla_cacahuete', name: 'Mantequilla de cacahuete', category: 'frutos_secos', carbsPer100g: 20.0, caloriesPer100g: 588, containsGluten: false),
    const Food(id: 'g_crema_almendra', name: 'Crema de almendra',         category: 'frutos_secos', carbsPer100g: 19.0, caloriesPer100g: 614, containsGluten: false),
    const Food(id: 'g_frutos_secos_mix', name: 'Frutos secos variados (mix)', category: 'frutos_secos', carbsPer100g: 19.0, caloriesPer100g: 600, containsGluten: false),

    // ── Dulces y bollería (ampliado) ─────────────────────────────────────── //
    const Food(id: 'g_chocolate_blanco', name: 'Chocolate blanco',        category: 'dulces',   carbsPer100g: 59.0, caloriesPer100g: 539, containsGluten: false),
    const Food(id: 'g_nutella',        name: 'Crema de cacao y avellanas', category: 'dulces',   carbsPer100g: 57.0, caloriesPer100g: 539, containsGluten: false),
    const Food(id: 'g_mermelada',      name: 'Mermelada',                 category: 'dulces',   carbsPer100g: 49.0, caloriesPer100g: 200, containsGluten: false),
    const Food(id: 'g_caramelos',      name: 'Caramelos',                 category: 'dulces',   carbsPer100g: 87.0, caloriesPer100g: 394, containsGluten: false),
    const Food(id: 'g_gominolas',      name: 'Gominolas',                 category: 'dulces',   carbsPer100g: 77.0, caloriesPer100g: 343, containsGluten: false),
    const Food(id: 'g_helado_vainilla',name: 'Helado de vainilla',        category: 'dulces',   carbsPer100g: 24.0, caloriesPer100g: 207, containsGluten: false),
    const Food(id: 'g_helado_chocolate',name:'Helado de chocolate',       category: 'dulces',   carbsPer100g: 24.0, caloriesPer100g: 216, containsGluten: false),
    const Food(id: 'g_sorbete',        name: 'Sorbete de frutas',         category: 'dulces',   carbsPer100g: 30.0, caloriesPer100g: 130, containsGluten: false),
    const Food(id: 'g_turron_jijona',  name: 'Turrón de Jijona',          category: 'dulces',   carbsPer100g: 40.0, caloriesPer100g: 502, containsGluten: false),
    const Food(id: 'g_turron_alicante',name: 'Turrón de Alicante',        category: 'dulces',   carbsPer100g: 60.0, caloriesPer100g: 480, containsGluten: false),
    const Food(id: 'g_mazapan',        name: 'Mazapán',                   category: 'dulces',   carbsPer100g: 55.0, caloriesPer100g: 480, containsGluten: false),
    const Food(id: 'g_polvoron',       name: 'Polvorón',                  category: 'dulces',   carbsPer100g: 55.0, caloriesPer100g: 530, containsGluten: true),
    const Food(id: 'g_membrillo_dulce',name: 'Dulce de membrillo',        category: 'dulces',   carbsPer100g: 65.0, caloriesPer100g: 250, containsGluten: false),
    const Food(id: 'g_sirope_arce',    name: 'Sirope de arce',            category: 'dulces',   carbsPer100g: 67.0, caloriesPer100g: 260, containsGluten: false),
    const Food(id: 'g_edulcorante',    name: 'Edulcorante (estevia)',     category: 'dulces',   carbsPer100g: 0.0,  caloriesPer100g: 0,   containsGluten: false),
    const Food(id: 'g_donut',          name: 'Donut',                     category: 'bolleria', carbsPer100g: 51.0, caloriesPer100g: 452, containsGluten: true),
    const Food(id: 'g_magdalena',      name: 'Magdalena',                 category: 'bolleria', carbsPer100g: 53.0, caloriesPer100g: 390, containsGluten: true),
    const Food(id: 'g_napolitana',     name: 'Napolitana de chocolate',   category: 'bolleria', carbsPer100g: 48.0, caloriesPer100g: 410, containsGluten: true),
    const Food(id: 'g_palmera',        name: 'Palmera de chocolate',      category: 'bolleria', carbsPer100g: 50.0, caloriesPer100g: 480, containsGluten: true),
    const Food(id: 'g_ensaimada',      name: 'Ensaimada',                 category: 'bolleria', carbsPer100g: 52.0, caloriesPer100g: 420, containsGluten: true),
    const Food(id: 'g_bizcocho',       name: 'Bizcocho casero',           category: 'bolleria', carbsPer100g: 50.0, caloriesPer100g: 370, containsGluten: true),
    const Food(id: 'g_tarta_queso',    name: 'Tarta de queso',            category: 'bolleria', carbsPer100g: 25.0, caloriesPer100g: 321, containsGluten: true),
    const Food(id: 'g_tarta_chocolate',name: 'Tarta de chocolate',        category: 'bolleria', carbsPer100g: 50.0, caloriesPer100g: 371, containsGluten: true),
    const Food(id: 'g_galletas_chocolate', name: 'Galletas con chocolate', category: 'bolleria', carbsPer100g: 64.0, caloriesPer100g: 480, containsGluten: true),
    const Food(id: 'g_galletas_integral', name: 'Galletas integrales',    category: 'bolleria', carbsPer100g: 68.0, caloriesPer100g: 440, containsGluten: true),
    const Food(id: 'g_galletas_sin_gluten', name: 'Galletas sin gluten',  category: 'bolleria', carbsPer100g: 70.0, caloriesPer100g: 450, containsGluten: false),
    const Food(id: 'g_churros',        name: 'Churros',                   category: 'bolleria', carbsPer100g: 48.0, caloriesPer100g: 400, containsGluten: true),
    const Food(id: 'g_rosquillas',     name: 'Rosquillas',                category: 'bolleria', carbsPer100g: 55.0, caloriesPer100g: 430, containsGluten: true),
    const Food(id: 'g_pan_brioche',    name: 'Pan brioche',               category: 'bolleria', carbsPer100g: 50.0, caloriesPer100g: 380, containsGluten: true),

    // ── Bebidas (ampliado) ───────────────────────────────────────────────── //
    const Food(id: 'g_zumo_manzana',   name: 'Zumo de manzana',           category: 'bebidas', carbsPer100g: 11.3, caloriesPer100g: 46,  containsGluten: false),
    const Food(id: 'g_zumo_piña',      name: 'Zumo de piña',              category: 'bebidas', carbsPer100g: 13.0, caloriesPer100g: 53,  containsGluten: false),
    const Food(id: 'g_zumo_uva',       name: 'Zumo de uva',               category: 'bebidas', carbsPer100g: 16.0, caloriesPer100g: 60,  containsGluten: false),
    const Food(id: 'g_zumo_tomate',    name: 'Zumo de tomate',            category: 'bebidas', carbsPer100g: 4.2,  caloriesPer100g: 17,  containsGluten: false),
    const Food(id: 'g_refresco_naranja', name: 'Refresco de naranja',     category: 'bebidas', carbsPer100g: 11.0, caloriesPer100g: 45,  containsGluten: false),
    const Food(id: 'g_refresco_limon', name: 'Refresco de limón',         category: 'bebidas', carbsPer100g: 10.0, caloriesPer100g: 41,  containsGluten: false),
    const Food(id: 'g_tonica',         name: 'Tónica',                    category: 'bebidas', carbsPer100g: 8.6,  caloriesPer100g: 34,  containsGluten: false),
    const Food(id: 'g_bebida_isotonica', name: 'Bebida isotónica',        category: 'bebidas', carbsPer100g: 6.0,  caloriesPer100g: 25,  containsGluten: false),
    const Food(id: 'g_bebida_energetica', name: 'Bebida energética',      category: 'bebidas', carbsPer100g: 11.0, caloriesPer100g: 45,  containsGluten: false),
    const Food(id: 'g_horchata',       name: 'Horchata',                  category: 'bebidas', carbsPer100g: 14.0, caloriesPer100g: 90,  containsGluten: false),
    const Food(id: 'g_vino_tinto',     name: 'Vino tinto',                category: 'bebidas', carbsPer100g: 2.6,  caloriesPer100g: 85,  containsGluten: false),
    const Food(id: 'g_vino_blanco',    name: 'Vino blanco',               category: 'bebidas', carbsPer100g: 2.6,  caloriesPer100g: 82,  containsGluten: false),
    const Food(id: 'g_cava',           name: 'Cava / Espumoso',           category: 'bebidas', carbsPer100g: 1.5,  caloriesPer100g: 80,  containsGluten: false),
    const Food(id: 'g_sidra',          name: 'Sidra',                     category: 'bebidas', carbsPer100g: 2.3,  caloriesPer100g: 41,  containsGluten: false),
    const Food(id: 'g_cerveza_sin_alcohol', name: 'Cerveza sin alcohol',  category: 'bebidas', carbsPer100g: 4.8,  caloriesPer100g: 25,  containsGluten: true),
    const Food(id: 'g_te',             name: 'Té (infusión, sin azúcar)', category: 'bebidas', carbsPer100g: 0.0,  caloriesPer100g: 1,   containsGluten: false),
    const Food(id: 'g_cafe',           name: 'Café (solo, sin azúcar)',   category: 'bebidas', carbsPer100g: 0.0,  caloriesPer100g: 2,   containsGluten: false),
    const Food(id: 'g_cafe_leche',     name: 'Café con leche',            category: 'bebidas', carbsPer100g: 2.4,  caloriesPer100g: 28,  containsGluten: false),
    const Food(id: 'g_chocolate_caliente', name: 'Chocolate caliente',    category: 'bebidas', carbsPer100g: 12.0, caloriesPer100g: 90,  containsGluten: false),
    const Food(id: 'g_batido_chocolate', name: 'Batido de chocolate',     category: 'bebidas', carbsPer100g: 14.0, caloriesPer100g: 95,  containsGluten: false),
    const Food(id: 'g_batido_fresa',   name: 'Batido de fresa',           category: 'bebidas', carbsPer100g: 13.0, caloriesPer100g: 90,  containsGluten: false),
    const Food(id: 'g_agua',           name: 'Agua',                      category: 'bebidas', carbsPer100g: 0.0,  caloriesPer100g: 0,   containsGluten: false),
    const Food(id: 'g_agua_coco',      name: 'Agua de coco',              category: 'bebidas', carbsPer100g: 3.7,  caloriesPer100g: 19,  containsGluten: false),

    // ── Platos preparados / salsas / otros (ampliado) ────────────────────── //
    const Food(id: 'g_tortilla_patatas', name: 'Tortilla de patatas',     category: 'plato', carbsPer100g: 12.0, caloriesPer100g: 200, containsGluten: false),
    const Food(id: 'g_paella',         name: 'Paella (mixta)',            category: 'plato', carbsPer100g: 22.0, caloriesPer100g: 160, containsGluten: false),
    const Food(id: 'g_pizza_margarita',name: 'Pizza margarita',           category: 'plato', carbsPer100g: 33.0, caloriesPer100g: 266, containsGluten: true),
    const Food(id: 'g_pizza_jamon',    name: 'Pizza de jamón y queso',    category: 'plato', carbsPer100g: 30.0, caloriesPer100g: 270, containsGluten: true),
    const Food(id: 'g_lasagna_carne',  name: 'Lasaña de carne (preparada)', category: 'plato', carbsPer100g: 12.0, caloriesPer100g: 150, containsGluten: true),
    const Food(id: 'g_canelones',      name: 'Canelones (rellenos)',      category: 'plato', carbsPer100g: 15.0, caloriesPer100g: 165, containsGluten: true),
    const Food(id: 'g_croquetas',      name: 'Croquetas',                 category: 'plato', carbsPer100g: 20.0, caloriesPer100g: 240, containsGluten: true),
    const Food(id: 'g_empanadillas',   name: 'Empanadillas',              category: 'plato', carbsPer100g: 28.0, caloriesPer100g: 290, containsGluten: true),
    const Food(id: 'g_nuggets_pollo',  name: 'Nuggets de pollo',          category: 'plato', carbsPer100g: 15.0, caloriesPer100g: 250, containsGluten: true),
    const Food(id: 'g_patatas_fritas', name: 'Patatas fritas',            category: 'plato', carbsPer100g: 35.0, caloriesPer100g: 312, containsGluten: false),
    const Food(id: 'g_patatas_chips',  name: 'Patatas chips (bolsa)',     category: 'plato', carbsPer100g: 50.0, caloriesPer100g: 536, containsGluten: false),
    const Food(id: 'g_ensaladilla',    name: 'Ensaladilla rusa',          category: 'plato', carbsPer100g: 9.0,  caloriesPer100g: 145, containsGluten: false),
    const Food(id: 'g_gazpacho',       name: 'Gazpacho',                  category: 'plato', carbsPer100g: 4.0,  caloriesPer100g: 40,  containsGluten: false),
    const Food(id: 'g_salmorejo',      name: 'Salmorejo',                 category: 'plato', carbsPer100g: 5.5,  caloriesPer100g: 90,  containsGluten: true),
    const Food(id: 'g_cocido',         name: 'Cocido (plato completo)',   category: 'plato', carbsPer100g: 8.0,  caloriesPer100g: 140, containsGluten: false),
    const Food(id: 'g_fabada',         name: 'Fabada asturiana',          category: 'plato', carbsPer100g: 12.0, caloriesPer100g: 160, containsGluten: false),
    const Food(id: 'g_sushi_mix',      name: 'Sushi (variado)',           category: 'plato', carbsPer100g: 28.0, caloriesPer100g: 145, containsGluten: false),
    const Food(id: 'g_ramen',          name: 'Ramen',                     category: 'plato', carbsPer100g: 13.0, caloriesPer100g: 90,  containsGluten: true),
    const Food(id: 'g_curry_pollo',    name: 'Curry de pollo',            category: 'plato', carbsPer100g: 6.0,  caloriesPer100g: 165, containsGluten: false),
    const Food(id: 'g_guacamole',      name: 'Guacamole',                 category: 'plato', carbsPer100g: 6.0,  caloriesPer100g: 150, containsGluten: false),
    const Food(id: 'g_mayonesa',       name: 'Mayonesa',                  category: 'plato', carbsPer100g: 1.0,  caloriesPer100g: 680, containsGluten: false),
    const Food(id: 'g_ketchup',        name: 'Kétchup',                   category: 'plato', carbsPer100g: 24.0, caloriesPer100g: 100, containsGluten: false),
    const Food(id: 'g_mostaza',        name: 'Mostaza',                   category: 'plato', carbsPer100g: 5.0,  caloriesPer100g: 70,  containsGluten: false),
    const Food(id: 'g_alioli',         name: 'Alioli',                    category: 'plato', carbsPer100g: 1.5,  caloriesPer100g: 600, containsGluten: false),
    const Food(id: 'g_pesto',          name: 'Salsa pesto',               category: 'plato', carbsPer100g: 4.0,  caloriesPer100g: 450, containsGluten: false),
    const Food(id: 'g_salsa_soja',     name: 'Salsa de soja',             category: 'plato', carbsPer100g: 5.6,  caloriesPer100g: 53,  containsGluten: true),
    const Food(id: 'g_vinagre',        name: 'Vinagre',                   category: 'plato', carbsPer100g: 0.4,  caloriesPer100g: 19,  containsGluten: false),
    const Food(id: 'g_aceite_girasol', name: 'Aceite de girasol',         category: 'plato', carbsPer100g: 0.0,  caloriesPer100g: 884, containsGluten: false),
    const Food(id: 'g_caldo_verduras', name: 'Caldo de verduras',         category: 'plato', carbsPer100g: 1.0,  caloriesPer100g: 10,  containsGluten: false),
    const Food(id: 'g_caldo_pollo',    name: 'Caldo de pollo',            category: 'plato', carbsPer100g: 0.5,  caloriesPer100g: 15,  containsGluten: false),
    const Food(id: 'g_sopa_verduras',  name: 'Sopa de verduras',          category: 'plato', carbsPer100g: 5.0,  caloriesPer100g: 35,  containsGluten: false),
    const Food(id: 'g_crema_calabaza', name: 'Crema de calabaza',         category: 'plato', carbsPer100g: 8.0,  caloriesPer100g: 60,  containsGluten: false),
    const Food(id: 'g_pure_patata',    name: 'Puré de patata',            category: 'plato', carbsPer100g: 14.0, caloriesPer100g: 88,  containsGluten: false),
  ];
}