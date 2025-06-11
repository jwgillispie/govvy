// lib/widgets/shared/grouped_representative_list.dart

import 'package:flutter/material.dart';
import 'package:govvy/models/representative_model.dart';
import 'package:govvy/utils/government_level_helper.dart';
import 'package:govvy/widgets/representatives/representative_card.dart';

class GroupedRepresentativeList extends StatelessWidget {
  final List<Representative> representatives;
  final Function(Representative) onRepresentativeTap;
  final bool groupByLevel;
  final bool showLevelHeaders;
  final bool collapsible;

  const GroupedRepresentativeList({
    Key? key,
    required this.representatives,
    required this.onRepresentativeTap,
    this.groupByLevel = true,
    this.showLevelHeaders = true,
    this.collapsible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!groupByLevel) {
      // Simple list without grouping
      return _buildSimpleList();
    }

    // Group representatives by government level
    final groupedReps = GovernmentLevelHelper.groupByLevel<Representative>(
      representatives,
      (rep) => GovernmentLevelHelper.getLevelFromRepresentative(rep),
    );

    // Remove empty groups and build sections
    final sections = <Widget>[];
    
    for (final level in GovernmentLevel.values) {
      final repsInLevel = groupedReps[level]!;
      if (repsInLevel.isEmpty) continue;

      // Sort representatives within each level by name
      repsInLevel.sort((a, b) => a.name.compareTo(b.name));

      if (showLevelHeaders) {
        sections.add(_buildLevelHeader(level, repsInLevel.length));
      }

      if (collapsible) {
        sections.add(_buildCollapsibleSection(level, repsInLevel));
      } else {
        sections.addAll(_buildRepresentativeCards(repsInLevel));
      }
    }

    return ListView(
      children: sections,
    );
  }

  Widget _buildSimpleList() {
    // Sort by name for simple list
    final sortedReps = List<Representative>.from(representatives)
      ..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      itemCount: sortedReps.length,
      itemBuilder: (context, index) {
        final rep = sortedReps[index];
        return RepresentativeCard(
          representative: rep,
          onTap: () => onRepresentativeTap(rep),
        );
      },
    );
  }

  Widget _buildLevelHeader(GovernmentLevel level, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GovernmentLevelHelper.getLevelLightColor(level),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GovernmentLevelHelper.getLevelColor(level).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            GovernmentLevelHelper.getLevelIcon(level),
            color: GovernmentLevelHelper.getLevelColor(level),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '${GovernmentLevelHelper.getLevelDisplayName(level)} Representatives',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GovernmentLevelHelper.getLevelColor(level),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: GovernmentLevelHelper.getLevelColor(level),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection(GovernmentLevel level, List<Representative> reps) {
    return _CollapsibleSection(
      level: level,
      representatives: reps,
      onRepresentativeTap: onRepresentativeTap,
    );
  }

  List<Widget> _buildRepresentativeCards(List<Representative> reps) {
    return reps.map((rep) => RepresentativeCard(
      representative: rep,
      onTap: () => onRepresentativeTap(rep),
    )).toList();
  }
}

class _CollapsibleSection extends StatefulWidget {
  final GovernmentLevel level;
  final List<Representative> representatives;
  final Function(Representative) onRepresentativeTap;

  const _CollapsibleSection({
    Key? key,
    required this.level,
    required this.representatives,
    required this.onRepresentativeTap,
  }) : super(key: key);

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true; // Start expanded

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggleExpanded,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: GovernmentLevelHelper.getLevelLightColor(widget.level),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GovernmentLevelHelper.getLevelColor(widget.level).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  GovernmentLevelHelper.getLevelIcon(widget.level),
                  color: GovernmentLevelHelper.getLevelColor(widget.level),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${GovernmentLevelHelper.getLevelDisplayName(widget.level)} Representatives',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GovernmentLevelHelper.getLevelColor(widget.level),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GovernmentLevelHelper.getLevelColor(widget.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.representatives.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.expand_more,
                    color: GovernmentLevelHelper.getLevelColor(widget.level),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            children: widget.representatives.map((rep) => RepresentativeCard(
              representative: rep,
              onTap: () => widget.onRepresentativeTap(rep),
            )).toList(),
          ),
        ),
      ],
    );
  }
}