class SpecializationMapper {
  static String mapToCategory(List<String> specializations) {
    if (specializations.isEmpty) return "nursing";

    final spec = specializations.first.toLowerCase();

    switch (spec) {
      case 'nurse':
      case 'pielęgniarka':
        return 'nursing';

      case 'physiotherapist':
      case 'fizjoterapeuta':
        return 'physiotherapy';

      default:
        return 'nursing';
    }
  }
}