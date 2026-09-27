import 'dart:convert';

// Synthetic HTML solely for regression tests; never imported by the app.
String offerHtml(
    {String key = 'playstation_us:EXAMPLE',
    String affiliation = 'playstation_us',
    String title = 'Example',
    String category = 'ps5',
    String currency = 'USD',
    String variant = 'digital',
    num price = 1999,
    num discount = 4000,
    String url = 'https://store.playstation.com/en-us/product/EXAMPLE',
    bool available = true}) {
  final data = jsonEncode({
    'currency': currency,
    'items': [
      {
        'item_name': title,
        'affiliation': affiliation,
        'item_category': category,
        'item_variant': variant,
        'price': price,
        'discount': discount
      }
    ]
  });
  return '''<script>outAnalytics['$key'] = $data
  </script><table><tr><td><a data-out-analytics-id="$key" href="$url">Store</a></td>
  <td>${available ? '\$${(price / 100).toStringAsFixed(2)}' : 'Unavailable'}</td>
  <td><a data-out-analytics-id="$key" href="$url">Sale ends October 8</a></td></tr></table>''';
}

String listingHtml(List<String> paths, {int? nextPage}) =>
    '''<form action="/search"></form>
  ${paths.map((p) => '<a class="main-link flex-grow-1" href="/items/$p"><h6>$p</h6></a>').join()}
  ${nextPage == null ? '' : '<ul class="pagination"><li class="page-item"><a href="?page=$nextPage">Next</a></li></ul>'}''';
