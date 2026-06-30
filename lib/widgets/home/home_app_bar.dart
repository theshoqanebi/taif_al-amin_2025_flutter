import 'package:flutter/material.dart';
import 'package:taif_alamin/widgets/home/nav_item.dart';

class HomeAppBar extends StatefulWidget {
  final List<NavItem> navItems;
  final int selected;
  final Function(int) onClick;
  const HomeAppBar({
    super.key,
    required this.navItems,
    required this.selected,
    required this.onClick,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  late List<bool> _hoveredStates;

  @override
  void initState() {
    super.initState();
    _hoveredStates = List.filled(widget.navItems.length, false);
  }

  Color _getColor(int index) {
    if (index == widget.selected) return Colors.white;
    if (_hoveredStates[index]) return Colors.black;
    return const Color(0xFF66758C);
  }

  double _getSize(int index) {
    if (index == widget.selected) return 20;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.maxFinite,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E3E5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: widget.navItems.asMap().entries.map((entry) {
              return InkWell(
                onTap: () => widget.onClick(entry.key),
                onHover: (isHovered) {
                  setState(() => _hoveredStates[entry.key] = isHovered);
                },
                child: entry.key == widget.selected
                    ? Container(
                        width: 120,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFF003763),
                        ),
                        child: Center(
                          child: Text(
                            entry.value.title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: _getColor(entry.key),
                              fontSize: _getSize(entry.key),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 120,
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            entry.value.title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: _getColor(entry.key),
                              fontSize: _getSize(entry.key),
                            ),
                          ),
                        ),
                      ),
              );
            }).toList(),
          ),
          const Text(
            'طيف الأمين',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: Color(0xFF00213F),
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
