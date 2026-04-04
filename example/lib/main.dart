import 'services/feature_flag_service.dart';

void main() {
  final service = FeatureFlagService(MockRemoteConfig());
  service.readCheckoutRevampFlag();
  service.readHomeBannerText();
  service.readPromoLimit();
  service.readProductTileAspectRatio();
}
