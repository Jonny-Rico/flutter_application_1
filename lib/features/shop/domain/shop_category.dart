enum ShopCategory {
  groceries('groceries', 'Groceries'),
  household('household', 'Household'),
  other('other', 'Other');

  const ShopCategory(this.value, this.label);

  final String value;
  final String label;

  static ShopCategory fromValue(String? value) {
    return ShopCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ShopCategory.other,
    );
  }
}
