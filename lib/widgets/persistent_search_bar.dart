import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/search_controller.dart';
import '../core/theme/app_colors.dart';
import 'hi.dart';

/// Barre de recherche persistante affichée dans le header du panneau.
class PersistentSearchBar extends StatefulWidget {
  const PersistentSearchBar({super.key});

  @override
  State<PersistentSearchBar> createState() => _PersistentSearchBarState();
}

class _PersistentSearchBarState extends State<PersistentSearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      HermesSearch.instance.open.value =
          _focus.hasFocus || HermesSearch.instance.query.value.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.black,
      child: Row(
        children: [
          const Hi(AppIcons.tabSearch, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: (v) {
                HermesSearch.instance.setQuery(v);
                HermesSearch.instance.open.value =
                    v.isNotEmpty || _focus.hasFocus;
              },
              style: const TextStyle(color: Colors.white, fontSize: 12),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'MSISDN, nom, contrat, ICE…',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: HermesSearch.instance.query,
            builder: (_, q, _) {
              if (q.isEmpty) return const SizedBox.shrink();
              return InkWell(
                onTap: () {
                  _ctrl.clear();
                  HermesSearch.instance.clear();
                  _focus.requestFocus();
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Hi(AppIcons.close, size: 12, color: Colors.white70),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
