import 'package:diappbetes/services/dose_service.dart';
import 'package:diappbetes/services/glucose_service.dart';
import 'package:diappbetes/services/tir_service.dart';
import 'package:diappbetes/services/username_service.dart';
import 'package:diappbetes/utils/admin_nav_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoseService.calculate', () {
    const s = DoseSettings(ratio: 10, fsi: 50);

    test('solo comida: HC / ratio', () {
      expect(DoseService.calculate(totalHc: 60, glucose: 110, settings: s), 6.0);
    });

    test('suma corrección por glucemia alta', () {
      // 60/10 + (210-110)/50 = 6 + 2
      expect(DoseService.calculate(totalHc: 60, glucose: 210, settings: s), 8.0);
    });

    test('nunca devuelve negativo', () {
      expect(DoseService.calculate(totalHc: 0, glucose: 60, settings: s), 0);
    });

    test('redondea a 1 decimal', () {
      expect(DoseService.calculate(totalHc: 25, glucose: 110, settings: s), 2.5);
      expect(DoseService.calculate(totalHc: 33, glucose: 110, settings: s), 3.3);
    });
  });

  group('DoseService.breakdown', () {
    const s = DoseSettings(ratio: 10, fsi: 50);

    test('separa comida y corrección', () {
      final b = DoseService.breakdown(totalHc: 60, glucose: 210, settings: s);
      expect(b.mealUnits, 6.0);
      expect(b.correctionUnits, 2.0);
      expect(b.total, 8.0);
    });

    test('la corrección puede ser negativa y el total nunca lo es', () {
      final b = DoseService.breakdown(totalHc: 10, glucose: 60, settings: s);
      expect(b.correctionUnits, -1.0);
      expect(b.total, 0.0); // 1 - 1
      final low = DoseService.breakdown(totalHc: 0, glucose: 60, settings: s);
      expect(low.total, 0.0);
    });
  });

  group('DoseService.checkGlucose', () {
    test('rango normal', () {
      expect(DoseService.checkGlucose(110), GlucoseCheck.ok);
      expect(DoseService.checkGlucose(70), GlucoseCheck.ok);
    });

    test('hipoglucemia', () {
      expect(DoseService.checkGlucose(69), GlucoseCheck.low);
      expect(DoseService.checkGlucose(20), GlucoseCheck.low);
    });

    test('valores imposibles', () {
      expect(DoseService.checkGlucose(19), GlucoseCheck.implausible);
      expect(DoseService.checkGlucose(601), GlucoseCheck.implausible);
      expect(DoseService.checkGlucose(double.nan), GlucoseCheck.implausible);
    });
  });

  group('DoseService.parseMinutes', () {
    test('formato normal', () {
      expect(DoseService.parseMinutes('07:30'), 450);
      expect(DoseService.parseMinutes('00:00'), 0);
    });

    test('Ajustes guarda 24:00 como fin del día', () {
      expect(DoseService.parseMinutes('24:00'), 1440);
    });

    test('rechaza formatos inválidos', () {
      expect(DoseService.parseMinutes('25:00'), isNull);
      expect(DoseService.parseMinutes('12:60'), isNull);
      expect(DoseService.parseMinutes('abc'), isNull);
      expect(DoseService.parseMinutes(null), isNull);
    });

    test('un tramo hasta 24:00 cubre el final del día', () {
      expect(DoseService.inRange(23 * 60 + 59, 0, 1440), isTrue);
      expect(DoseService.inRange(0, 0, 1440), isTrue);
    });
  });

  group('TirStats.from', () {
    test('reparte en rango / bajas / altas y calcula la media', () {
      final s = TirStats.from([60, 100, 150, 200], 70, 180);
      expect(s.count, 4);
      expect(s.lowPct, 25);
      expect(s.highPct, 25);
      expect(s.inRangePct, 50);
      expect(s.average, 127.5);
    });

    test('sin lecturas devuelve vacío', () {
      expect(TirStats.from([], 70, 180).count, 0);
    });
  });

  group('DoseService.inRange', () {
    int m(int h, int min) => h * 60 + min;

    test('tramo normal', () {
      expect(DoseService.inRange(m(8, 0), m(7, 0), m(12, 0)), isTrue);
      expect(DoseService.inRange(m(12, 0), m(7, 0), m(12, 0)), isFalse); // fin exclusivo
      expect(DoseService.inRange(m(6, 59), m(7, 0), m(12, 0)), isFalse);
    });

    test('tramo que cruza la medianoche', () {
      expect(DoseService.inRange(m(23, 0), m(22, 0), m(6, 0)), isTrue);
      expect(DoseService.inRange(m(2, 0), m(22, 0), m(6, 0)), isTrue);
      expect(DoseService.inRange(m(12, 0), m(22, 0), m(6, 0)), isFalse);
    });

    test('23:59 cuenta como fin de día', () {
      expect(DoseService.inRange(m(23, 59), m(18, 0), m(23, 59)), isTrue);
    });
  });

  group('UsernameService.normalize', () {
    test('recorta y pasa a minúsculas', () {
      expect(UsernameService.normalize('  JuAn  '), 'juan');
    });
  });

  group('AdminNavHelper.isAdminRole', () {
    test('acepta variantes de administrador', () {
      expect(AdminNavHelper.isAdminRole('administrador'), isTrue);
      expect(AdminNavHelper.isAdminRole('Administrador'), isTrue);
      expect(AdminNavHelper.isAdminRole(' admin '), isTrue);
    });

    test('rechaza el resto', () {
      expect(AdminNavHelper.isAdminRole('Usuario'), isFalse);
      expect(AdminNavHelper.isAdminRole(null), isFalse);
      expect(AdminNavHelper.isAdminRole(''), isFalse);
    });
  });

  group('GlucoseService.isWithinDays', () {
    final start = DateTime(2026, 3, 10, 15, 30);
    final end = DateTime(2026, 3, 12, 9, 0);

    test('incluye el día inicial completo y el final completo', () {
      expect(GlucoseService.isWithinDays(DateTime(2026, 3, 10, 0, 0), start, end), isTrue);
      expect(GlucoseService.isWithinDays(DateTime(2026, 3, 12, 23, 59), start, end), isTrue);
    });

    test('excluye el día anterior y el posterior', () {
      expect(GlucoseService.isWithinDays(DateTime(2026, 3, 9, 23, 59), start, end), isFalse);
      expect(GlucoseService.isWithinDays(DateTime(2026, 3, 13, 0, 0), start, end), isFalse);
    });
  });
}
