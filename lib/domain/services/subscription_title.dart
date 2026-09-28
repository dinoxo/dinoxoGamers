String subscriptionTitleKey(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'[™®©]'), '')
    .replaceAll(
        RegExp(
            r'\s*(?:ps4\s*&\s*ps5|ps5\s*&\s*ps4|standard edition|digital edition)\s*$',
            caseSensitive: false),
        '')
    .replaceAll(RegExp(r"[’']"), '')
    .replaceAll(RegExp(r'[^a-z0-9à-ÿ]+'), ' ')
    .trim();
