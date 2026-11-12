import 'package:family_tasks/features/settings/presentation/widgets/settings_avatar_button.dart';
import 'package:flutter/material.dart';

/// App bar for the five root tabs: centered title and the account menu.
class RootAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RootAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  static const double barHeight = 56;

  @override
  Size get preferredSize => Size.fromHeight(
        barHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;
    final fontSize = (base?.fontSize ?? 22) * 0.882;

    return AppBar(
      toolbarHeight: barHeight,
      leadingWidth: barHeight,
      centerTitle: true,
      leading: const AccountMenuButton(),
      title: Text(
        title,
        style: base?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
