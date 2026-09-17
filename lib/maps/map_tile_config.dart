class MapTileConfig {
  static const String userAgentPackageName = 'com.timelineduel.app';
  static const String mapboxAccessToken =
      'pk.eyJ1IjoiZmxvd2lzdCIsImEiOiJjbW5kaTV6aGYxaTRtMnJxeXJ6ZDZ2eXR2In0.uxULlIx67d9dMQuN392PqQ';

  static const String _defaultStyleOwner = 'mapbox';
  static const String _defaultStyleId = 'streets-v12';
  static const bool useMysteryMapboxStyle = false;

  // After you publish a no-label style in Mapbox Studio,
  // set these two values and the mystery maps will switch over too.
  static const String mysteryStyleOwner = 'flowist';
  static const String mysteryStyleId = 'cmndijf5x001b01s70blp7q9s';

  static String _styleTilesUrl(String owner, String styleId) {
    return 'https://api.mapbox.com/styles/v1/'
        '$owner/$styleId/tiles/512/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';
  }

  static String get standardRasterUrlTemplate =>
      _styleTilesUrl(_defaultStyleOwner, _defaultStyleId);

  static bool get hasMysteryMapboxStyle =>
      useMysteryMapboxStyle &&
      mysteryStyleOwner.isNotEmpty &&
      mysteryStyleId.isNotEmpty;

  static String get mysteryNoLabelsUrlTemplate => hasMysteryMapboxStyle
      ? _styleTilesUrl(mysteryStyleOwner, mysteryStyleId)
      : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

  static List<String> get mysterySubdomains =>
      hasMysteryMapboxStyle ? const [] : const ['a', 'b', 'c', 'd'];
}
