import 'package:flutter/material.dart';
import '../../models/channel_category.dart';

class CategorySidebar extends StatelessWidget {
  final List<ChannelCategory> groups;
  final List<ChannelCategory> languages;
  final ChannelCategory? selected;
  final int totalCount;
  final ValueChanged<ChannelCategory?> onSelect;

  const CategorySidebar({
    super.key,
    required this.groups,
    required this.languages,
    required this.selected,
    required this.totalCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Container(
        color: const Color(0xFF1A1A2E),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
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
