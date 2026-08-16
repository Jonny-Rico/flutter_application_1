enum GroupRole {
  owner('owner'),
  member('member');

  const GroupRole(this.value);

  final String value;

  static GroupRole fromValue(String value) {
    return GroupRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => GroupRole.member,
    );
  }

  bool get isOwner => this == GroupRole.owner;
}