import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';

void main() {
  group('ApiStrategyTemplates', () {
    test('all built-in API templates generate valid strategy forms', () {
      expect(ApiStrategyTemplates.all, isNotEmpty);

      for (final template in ApiStrategyTemplates.all) {
        final form = StrategyFormData.fromTemplate(template);

        expect(form.validate(), isNull, reason: template.id);
        expect(form.name, template.name);
        expect(form.isWeightSumValid, isTrue, reason: template.id);
        expect(template.apiCapabilities, isNotEmpty, reason: template.id);
        expect(template.requiredFields, isNotEmpty, reason: template.id);
      }
    });

    test('generated form is detached from template form data', () {
      final template = ApiStrategyTemplates.all.first;
      final generated = StrategyFormData.fromTemplate(template);

      generated.name = '用户改名策略';

      expect(template.formData.name, template.name);
      expect(generated.name, '用户改名策略');
    });
  });
}
