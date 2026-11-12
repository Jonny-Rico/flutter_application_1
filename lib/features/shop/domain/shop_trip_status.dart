enum ShopTripStatus {
  active('active'),
  completed('completed'),
  ended('ended');

  const ShopTripStatus(this.value);

  final String value;

  bool get isClosed => this != ShopTripStatus.active;

  static ShopTripStatus fromValue(String? value) {
    return ShopTripStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ShopTripStatus.active,
    );
  }
}
