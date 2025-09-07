// lib/services/withings_config.dart
const String withingsClientId = '67fe8002160efd610b91b6014dd9598a737f154668cd9474919ccaa1f1264220';
const String withingsClientSecret = 'c51ef79f7b0b455113661bb674b8116a837b7d61e69fd89699fe376c7325d443';
const String withingsRedirectUri = 'virelink://withings-callback';

const String withingsAuthorizationEndpoint =
    'https://account.withings.com/oauth2_user/authorize2';
const String withingsTokenEndpoint =
    'https://wbsapi.withings.net/v2/oauth2';

const List<String> withingsScopes = <String>[
  'user.metrics',
];

// Secure Storage keys
const String kWithingsAccessKey = 'withings_access';
const String kWithingsRefreshKey = 'withings_refresh';
const String kWithingsAccessExpKey = 'withings_access_exp';
