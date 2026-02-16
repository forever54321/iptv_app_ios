import 'package:flutter/material.dart';
import '../../models/channel_category.dart';

class CategorySidebar extends StatelessWidget {
  final List<ChannelCategory> groups;
  final List<ChannelCategory> languages;
  final ChannelCategory? selected;
  final int totalCount;
  final ValueChanged<ChannelCategory?> onSelect;
  final bool asSheet;

  const CategorySidebar({
    super.key,
    required this.groups,
    required this.languages,
    required this.selected,
    required this.totalCount,
    required this.onSelect,
    this.asSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      shrinkWrap: asSheet,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (asSheet)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Text(
                  'Filter Channels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade200,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade400),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        _buildItem(context, 'All Channels', totalCount, null),
        if (groups.isNotEmpty) ...[
          _buildHeader(context, 'Categories'),
          ...groups.map((g) =>
              _buildItem(context, g.name, g.channelCount, g)),
        ],
        if (languages.isNotEmpty) ...[
          _buildHeader(context, 'Languages'),
          ...languages.map((l) =>
              _buildItem(context, l.name, l.channelCount, l)),
        ],
      ],
    );

    // When used as a bottom sheet, don't wrap in SizedBox/Container
    if (asSheet) {
      return listView;
    }

    return SafeArea(
      right: false,
      top: false,
      bottom: false,
      child: SizedBox(
        width: 250,
        child: Container(
          color: const Color(0xFF1A1A2E),
          child: listView,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, String name, int count, ChannelCategory? cat) {
    final isSelected = selected == cat;
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withValues(alpha: 0.3),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Text(
        '$count',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      onTap: () => onSelect(cat),
    );
  }
}
