final _trademarks = RegExp(r'[™®©]');
final _storeSuffix = RegExp(
    r'\s*(?:ps4\s*&\s*ps5|ps5\s*&\s*ps4|standard edition|digital edition)\s*$',
    caseSensitive: false);
final _apostrophes = RegExp(r"[’']");
final _membershipSuffix =
    RegExp(r'\s*\((?:playstation plus|ps plus)\)\s*$', caseSensitive: false);
final _nonTitleCharacters = RegExp(r'[^a-z0-9à-ÿ]+');

String subscriptionTitleKey(String title) => title
    .toLowerCase()
    .replaceAll(_trademarks, '')
    .replaceAll(_membershipSuffix, '')
    .replaceAll(_storeSuffix, '')
    .replaceAll(_apostrophes, '')
    .replaceAll(_nonTitleCharacters, ' ')
    .trim();
