import 'package:taif_alamin/data/constants/supply_type.dart';

/// Display name (company) -> belongTo key, grouped by supply type.
/// Mirrors the legacy *Pathes maps from the old app.

const Map<String, String> fabricCompanies = {
  'مبيعات السلطان': 'fabric1',
  'قماش علوش': 'fabric2',
  'قماش العوضي': 'fabric3',
  'قماش هانزو': 'fabric4',
  'أكسسوارات السلطان': 'fabric5',
  'نابليون': 'fabric6',
  'ANC': 'fabric7',
};

const Map<String, String> woodCompanies = {
  'خشب الروعة': 'wood1',
  'خشب الاوسكار (MDF)': 'wood1',
  'خشب ضياء زيارة': 'wood1',
  'سيد جعفر': 'mayarWoods',
};

const Map<String, String> spongeCompanies = {
  'مشتريات الاسفنج': 'sponge1',
  'حيدر السويدي': 'sponge2',
};

const Map<String, String> paintCompanies = {
  'اصباغ ناجي المعمار': 'paint1',
};

/// The companies map for a given supply type.
Map<String, String> companiesFor(SupplyType type) {
  switch (type) {
    case SupplyType.fabric:
      return fabricCompanies;
    case SupplyType.wood:
      return woodCompanies;
    case SupplyType.sponge:
      return spongeCompanies;
    case SupplyType.paint:
      return paintCompanies;
  }
}