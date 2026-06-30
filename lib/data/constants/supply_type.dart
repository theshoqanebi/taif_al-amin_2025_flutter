enum SupplyType {
  paint,
  sponge,
  wood,
  fabric;

  String toDisplayString() {
    switch (this) {
      case SupplyType.paint:
        return 'صبغ';
      case SupplyType.sponge:
        return 'إسفنج';
      case SupplyType.wood:
        return 'خشب';
      case SupplyType.fabric:
        return 'قماش';
    }
  }

  static SupplyType fromString(String value) {
    return SupplyType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SupplyType.paint,
    );
  }
}