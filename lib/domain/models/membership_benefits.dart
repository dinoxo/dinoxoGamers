import 'subscription_item.dart';

class MembershipBenefits {
  const MembershipBenefits(
      {required this.tier,
      required this.features,
      required this.sourceUrl,
      required this.checkedAt});
  final SubscriptionTier tier;
  final List<String> features;
  final String sourceUrl;
  final DateTime checkedAt;
}

class SubscriptionCatalog {
  const SubscriptionCatalog(
      {required this.items,
      this.benefits = const [],
      this.notices = const [],
      this.gamesVerified = true});
  final List<SubscriptionItem> items;
  final List<MembershipBenefits> benefits;
  final List<String> notices;
  final bool gamesVerified;
}
