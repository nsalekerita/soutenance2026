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

  const DashboardShell({
    super.key,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.child,
    this.actions,
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
            Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        actions: [
          ...?actions,
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
          _Sidebar(items: items, selectedIndex: selectedIndex, onSelect: onSelect),
          Expanded(child: child),
        ],
      )
          : child,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        backgroundColor: AppColors.white,
        destinations: items
            .map((i) => NavigationDestination(icon: Icon(i.icon), label: i.label))
            .toList(),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final List<NavEntry> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: items.length,
        itemBuilder: (context, index) => _SidebarItem(
          entry: items[index],
          selected: index == selectedIndex,
          onTap: () => onSelect(index),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavEntry entry;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({required this.entry, required this.selected, required this.onTap});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            onTap: widget.onTap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(widget.entry.icon, color: widget.selected ? AppColors.darkGreen : AppColors.textMuted, size: 20),
            title: Text(
              widget.entry.label,
              style: TextStyle(
                color: widget.selected ? AppColors.darkGreen : AppColors.textDark,
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
