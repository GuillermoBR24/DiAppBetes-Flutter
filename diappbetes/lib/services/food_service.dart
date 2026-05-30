import 'dart:convert';
import 'package:http/http.dart' as http;

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

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    this.iconUrl,
  });

  // Mapea la respuesta de OpenFoodFacts al modelo Food
  factory Food.fromOpenFoodFacts(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble()
        ?? (nutriments['carbohydrates'] as num?)?.toDouble()
        ?? 0.0;

    final calories = (nutriments['energy-kcal_100g'] as num?)?.toDouble()
        ?? (nutriments['energy-kcal'] as num?)?.toDouble()
        ?? ((nutriments['energy_100g'] as num?)?.toDouble() ?? 0.0) / 4.184;

    // Categoría desde la primera etiqueta de categoría disponible
    final categoriesTags = product['categories_tags'] as List<dynamic>? ?? [];
    final category = _mapCategory(
      product['food_groups_tags']?.first?.toString() ??
      categoriesTags.firstOrNull?.toString() ??
      '',
      product['product_name']?.toString() ?? '',
    );

    return Food(
      id:              product['id']?.toString() ?? product['_id']?.toString() ?? '',
      name:            product['product_name']?.toString()
                        ?? product['product_name_es']?.toString()
                        ?? product['product_name_en']?.toString()
                        ?? 'Desconocido',
      category:        category,
      carbsPer100g:    carbs,
      caloriesPer100g: calories,
      iconUrl:         product['image_front_small_url']?.toString()
                        ?? product['image_url']?.toString(),
    );
  }

  // Mapea etiquetas de OpenFoodFacts a las categorías del sistema
  static String _mapCategory(String tag, String name) {
    final t = tag.toLowerCase();
    final n = name.toLowerCase();

    if (t.contains('fruit') || n.contains('manzana') || n.contains('naranja') || n.contains('plátano')) return 'frutas';
    if (t.contains('meat') || t.contains('carne') || n.contains('pollo') || n.contains('cerdo') || n.contains('ternera')) return 'carnes';
    if (t.contains('fish') || t.contains('pescado') || n.contains('salmon') || n.contains('atún') || n.contains('merluza')) return 'pescados';
    if (t.contains('seafood') || t.contains('marisco') || n.contains('gamba') || n.contains('mejillón')) return 'mariscos';
    if (t.contains('vegetable') || t.contains('verdura') || n.contains('tomate') || n.contains('lechuga') || n.contains('zanahoria')) return 'verduras';
    if (t.contains('dairy') || t.contains('lácteo') || n.contains('leche') || n.contains('yogur') || n.contains('queso')) return 'lacteos';
    if (t.contains('cereal') || t.contains('bread') || t.contains('pasta') || n.contains('arroz') || n.contains('pan') || n.contains('pasta')) return 'cereales';
    if (t.contains('pastry') || t.contains('bollería') || n.contains('croissant') || n.contains('bollo') || n.contains('donut')) return 'bolleria';
    if (t.contains('sweet') || t.contains('chocolate') || n.contains('galleta') || n.contains('dulce') || n.contains('helado')) return 'dulces';
    if (t.contains('beverage') || t.contains('bebida') || t.contains('drink') || n.contains('zumo') || n.contains('refresco')) return 'bebidas';
    if (t.contains('legume') || t.contains('legumbre') || n.contains('lenteja') || n.contains('garbanzo') || n.contains('judía')) return 'legumbres';
    if (t.contains('nut') || t.contains('fruto') || n.contains('almendra') || n.contains('nuez') || n.contains('cacahuete')) return 'frutos_secos';
    return 'plato';
  }
}

// ---------------------------------------------------------------------------
// FoodService — búsqueda en OpenFoodFacts
// ---------------------------------------------------------------------------
class FoodService {
  static final FoodService _instance = FoodService._internal();
  factory FoodService() => _instance;
  FoodService._internal();

  static const _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  // Caché en memoria para no repetir búsquedas recientes
  final Map<String, List<Food>> _cache = {};

  // ── Buscar alimentos por término ─────────────────────────────────────── //
  Future<List<Food>> searchFoods(String query, {int pageSize = 24}) async {
    if (query.trim().isEmpty) return [];

    final cacheKey = query.trim().toLowerCase();
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'search_terms':   query.trim(),
        'search_simple':  '1',
        'action':         'process',
        'json':           '1',
        'page_size':      pageSize.toString(),
        'page':           '1',
        // Campos mínimos para reducir tamaño de respuesta
        'fields': 'id,_id,product_name,product_name_es,product_name_en,'
                  'nutriments,categories_tags,food_groups_tags,'
                  'image_front_small_url,image_url',
        // Filtrar productos con datos nutricionales completos
        'tagtype_0':  'countries',
        'tag_contains_0': 'contains',
        'tag_0':      'spain',
      });

      final response = await http.get(uri,
          headers: {'User-Agent': 'DiAppBetes/1.0 (contact@diappbetes.com)'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return _fallbackSearch(query);

      final json    = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (json['products'] as List<dynamic>? ?? []);

      final foods = products
          .map((p) {
            try {
              final f = Food.fromOpenFoodFacts(p as Map<String, dynamic>);
              // Filtrar productos sin nombre o sin datos nutricionales útiles
              if (f.name == 'Desconocido' || f.name.isEmpty) return null;
              return f;
            } catch (_) {
              return null;
            }
          })
          .whereType<Food>()
          .toList();

      // Si la API devuelve pocos resultados, complementa con fallback
      final result = foods.isNotEmpty ? foods : _fallbackSearch(query);
      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      // Si hay error de red, devuelve fallback
      return _fallbackSearch(query);
    }
  }

  // ── Fallback local para cuando la API no responde ─────────────────────── //
  List<Food> _fallbackSearch(String query) {
    final q = query.toLowerCase();
    return _localFoods.where((f) =>
        f.name.toLowerCase().contains(q) ||
        f.category.toLowerCase().contains(q)).toList();
  }

  // ── Lista local de alimentos comunes (siempre disponible offline) ─────── //
  static final List<Food> _localFoods = [
    const Food(id: 'l1',  name: 'Arroz blanco cocido',     category: 'cereales',     carbsPer100g: 28.0, caloriesPer100g: 130),
    const Food(id: 'l2',  name: 'Pan integral',            category: 'cereales',     carbsPer100g: 41.0, caloriesPer100g: 247),
    const Food(id: 'l3',  name: 'Pasta cocida',            category: 'cereales',     carbsPer100g: 25.0, caloriesPer100g: 131),
    const Food(id: 'l4',  name: 'Pechuga de pollo',        category: 'carnes',       carbsPer100g: 0.0,  caloriesPer100g: 165),
    const Food(id: 'l5',  name: 'Ternera magra',           category: 'carnes',       carbsPer100g: 0.0,  caloriesPer100g: 158),
    const Food(id: 'l6',  name: 'Salmón',                  category: 'pescados',     carbsPer100g: 0.0,  caloriesPer100g: 208),
    const Food(id: 'l7',  name: 'Merluza',                 category: 'pescados',     carbsPer100g: 0.0,  caloriesPer100g: 82),
    const Food(id: 'l8',  name: 'Manzana',                 category: 'frutas',       carbsPer100g: 14.0, caloriesPer100g: 52),
    const Food(id: 'l9',  name: 'Plátano',                 category: 'frutas',       carbsPer100g: 23.0, caloriesPer100g: 89),
    const Food(id: 'l10', name: 'Naranja',                 category: 'frutas',       carbsPer100g: 12.0, caloriesPer100g: 47),
    const Food(id: 'l11', name: 'Leche entera',            category: 'lacteos',      carbsPer100g: 4.8,  caloriesPer100g: 61),
    const Food(id: 'l12', name: 'Yogur natural',           category: 'lacteos',      carbsPer100g: 3.6,  caloriesPer100g: 59),
    const Food(id: 'l13', name: 'Queso manchego',          category: 'lacteos',      carbsPer100g: 0.5,  caloriesPer100g: 392),
    const Food(id: 'l14', name: 'Lentejas cocidas',        category: 'legumbres',    carbsPer100g: 20.0, caloriesPer100g: 116),
    const Food(id: 'l15', name: 'Garbanzos cocidos',       category: 'legumbres',    carbsPer100g: 18.0, caloriesPer100g: 164),
    const Food(id: 'l16', name: 'Tomate',                  category: 'verduras',     carbsPer100g: 3.9,  caloriesPer100g: 18),
    const Food(id: 'l17', name: 'Lechuga',                 category: 'verduras',     carbsPer100g: 2.9,  caloriesPer100g: 15),
    const Food(id: 'l18', name: 'Zanahoria',               category: 'verduras',     carbsPer100g: 10.0, caloriesPer100g: 41),
    const Food(id: 'l19', name: 'Almendras',               category: 'frutos_secos', carbsPer100g: 22.0, caloriesPer100g: 579),
    const Food(id: 'l20', name: 'Nueces',                  category: 'frutos_secos', carbsPer100g: 14.0, caloriesPer100g: 654),
    const Food(id: 'l21', name: 'Zumo de naranja natural', category: 'bebidas',      carbsPer100g: 10.4, caloriesPer100g: 45),
    const Food(id: 'l22', name: 'Gambas',                  category: 'mariscos',     carbsPer100g: 0.0,  caloriesPer100g: 85),
    const Food(id: 'l23', name: 'Chocolate negro 70%',     category: 'dulces',       carbsPer100g: 46.0, caloriesPer100g: 546),
    const Food(id: 'l24', name: 'Croissant',               category: 'bolleria',     carbsPer100g: 46.0, caloriesPer100g: 406),
    const Food(id: 'l25', name: 'Huevo',                   category: 'carnes',       carbsPer100g: 0.6,  caloriesPer100g: 155),
    const Food(id: 'l26', name: 'Patata cocida',           category: 'verduras',     carbsPer100g: 17.0, caloriesPer100g: 77),
    const Food(id: 'l27', name: 'Aceite de oliva',         category: 'plato',        carbsPer100g: 0.0,  caloriesPer100g: 884),
    const Food(id: 'l28', name: 'Atún en lata',            category: 'pescados',     carbsPer100g: 0.0,  caloriesPer100g: 116),
  ];

  // ── Obtener lista local completa (para mostrar al abrir el modal) ─────── //
  List<Food> getLocalFoods() => List.from(_localFoods);
}