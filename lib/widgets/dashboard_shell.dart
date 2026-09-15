import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_provider.dart';
import '../theme/app_colors.dart';

/// Coquille commune aux tableaux de bord (étudiant / entreprise / admin) :
/// barre de navigation professionnelle avec les items donnés, boutons avec
/// animation au survol (hover), et déconnexion.
class DashboardShell extends StatelessWidget {
  final String title;
  final List<NavEntry> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final List<int>? mobileIndices;

  const DashboardShell({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.mobileIndices,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        elevation: 0,
        title: Row(
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.white),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout, color: AppColors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                _Sidebar(
                    items: items,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect),
                Expanded(child: child),
              ],
            )
          : child,
          floatingActionButton: floatingActionButton,
      bottomNavigationBar: isWide
          ? null
          : _MobileNavigation(
              items: items,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              mobileIndices: mobileIndices,
            ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  final List<NavEntry> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<int>? mobileIndices;

  const _MobileNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.mobileIndices,
  });

  @override
  Widget build(BuildContext context) {
    final indices = mobileIndices ?? List<int>.generate(items.length, (index) => index);
    final visibleIndices = mobileIndices != null
      ? indices.take(4).toList()
      : (indices.length > 4 ? indices.take(3).toList() : indices);
    final visibleItems = visibleIndices.map((index) => items[index]).toList();
    final selectedVisibleIndex = visibleIndices.indexOf(selectedIndex);
    final selectedDestination = selectedVisibleIndex >= 0
      ? selectedVisibleIndex
      : (indices.length > visibleIndices.length ? visibleItems.length : 0);

    return NavigationBar(
      selectedIndex: selectedDestination,
      onDestinationSelected: (index) {
        if (index >= visibleItems.length) {
          _showMore(context, visibleIndices);
        } else {
          onSelect(visibleIndices[index]);
        }
      },
      backgroundColor: AppColors.white,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        ...visibleItems.map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          ),
        ),
        if (indices.length > visibleIndices.length)
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
      ],
    );
  }

  void _showMore(BuildContext context, List<int> visibleIndices) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            for (final index in List<int>.generate(items.length, (index) => index)
              .where((index) => !visibleIndices.contains(index)))
              ListTile(
                leading: Icon(items[index].icon),
                title: Text(items[index].label),
                selected: index == selectedIndex,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(index);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavEntry> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _Sidebar(
      {required this.items,
      required this.selectedIndex,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: items.length,
              itemBuilder: (context, index) => _SidebarItem(
                entry: items[index],
                selected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
            ),
          ),
          const Divider(height: 1),
          _SidebarItem(
            entry: const NavEntry(Icons.logout, 'Se déconnecter'),
            selected: false,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavEntry entry;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.entry, required this.selected, required this.onTap});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.gold.withOpacity(0.15)
                : (_hover ? AppColors.background : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.selected
                ? const Border(
                    left: BorderSide(color: AppColors.gold, width: 4))
                : null,
          ),
          child: ListTile(
            onTap: widget.onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(widget.entry.icon,
                color: widget.selected ? AppColors.gold : AppColors.textMuted,
                size: 20),
            title: Text(
              widget.entry.label,
              style: TextStyle(
                color: widget.selected ? AppColors.gold : AppColors.textDark,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavEntry {
  final IconData icon;
  final String label;
  const NavEntry(this.icon, this.label);
}
