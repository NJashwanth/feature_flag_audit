import 'mock_remote_config.dart';
import 'services/experiment_service.dart';
import 'services/feature_flag_service.dart';

void main() {
  final config = MockRemoteConfig();

  final flags = FeatureFlagService(config);
  flags.readCheckoutRevampFlag();
  flags.readHomeBannerText();
  flags.readPromoLimit();
  flags.readProductTileAspectRatio();
  flags.readDarkModeFlag();
  flags.readOnboardingVariant();

  final experiments = ExperimentService(config);
  experiments.readOnboardingVariant();
  experiments.readNewPdpExperiment();
  experiments.readPromoV1();
}
