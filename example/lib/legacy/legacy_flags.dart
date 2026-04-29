// This file is intentionally placed in lib/legacy/ which is listed under
// scan.exclude in feature_flag_audit.yaml.
//
// The scanner never sees this class, so any reference to LegacyFlags.*
// inside lib/ will appear as an unresolved reference in the audit output —
// exactly what would happen if the class had been deleted or moved out of
// the project without updating its call sites.
class LegacyFlags {
  static const promoV1 = 'promo_v1_enabled';
}
