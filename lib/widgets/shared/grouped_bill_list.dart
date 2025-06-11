// lib/widgets/shared/grouped_bill_list.dart

import 'package:flutter/material.dart';
import 'package:govvy/models/bill_model.dart';
import 'package:govvy/utils/government_level_helper.dart';
import 'package:govvy/widgets/bills/bill_card.dart';

class GroupedBillList extends StatelessWidget {
  final List<BillModel> bills;
  final Function(BillModel) onBillTap;
  final bool groupByLevel;
  final bool showLevelHeaders;
  final bool collapsible;

  const GroupedBillList({
    Key? key,
    required this.bills,
    required this.onBillTap,
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

    // Group bills by government level
    final groupedBills = GovernmentLevelHelper.groupByLevel<BillModel>(
      bills,
      (bill) => GovernmentLevelHelper.getLevelFromBillType(bill.type),
    );

    // Remove empty groups and build sections
    final sections = <Widget>[];
    
    for (final level in GovernmentLevel.values) {
      final billsInLevel = groupedBills[level]!;
      if (billsInLevel.isEmpty) continue;

      // Sort bills within each level by last action date (most recent first)
      billsInLevel.sort((a, b) {
        final dateA = a.lastActionDate ?? a.introducedDate ?? '';
        final dateB = b.lastActionDate ?? b.introducedDate ?? '';
        return dateB.compareTo(dateA);
      });

      if (showLevelHeaders) {
        sections.add(_buildLevelHeader(level, billsInLevel.length));
      }

      if (collapsible) {
        sections.add(_buildCollapsibleSection(level, billsInLevel));
      } else {
        sections.addAll(_buildBillCards(billsInLevel));
      }
    }

    return ListView(
      children: sections,
    );
  }

  Widget _buildSimpleList() {
    // Sort by last action date for simple list
    final sortedBills = List<BillModel>.from(bills)
      ..sort((a, b) {
        final dateA = a.lastActionDate ?? a.introducedDate ?? '';
        final dateB = b.lastActionDate ?? b.introducedDate ?? '';
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      itemCount: sortedBills.length,
      itemBuilder: (context, index) {
        final bill = sortedBills[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BillCard(
            bill: bill,
            onTap: () => onBillTap(bill),
          ),
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
            '${GovernmentLevelHelper.getLevelDisplayName(level)} Bills',
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

  Widget _buildCollapsibleSection(GovernmentLevel level, List<BillModel> bills) {
    return _CollapsibleBillSection(
      level: level,
      bills: bills,
      onBillTap: onBillTap,
    );
  }

  List<Widget> _buildBillCards(List<BillModel> bills) {
    return bills.map((bill) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BillCard(
        bill: bill,
        onTap: () => onBillTap(bill),
      ),
    )).toList();
  }
}

class _CollapsibleBillSection extends StatefulWidget {
  final GovernmentLevel level;
  final List<BillModel> bills;
  final Function(BillModel) onBillTap;

  const _CollapsibleBillSection({
    Key? key,
    required this.level,
    required this.bills,
    required this.onBillTap,
  }) : super(key: key);

  @override
  State<_CollapsibleBillSection> createState() => _CollapsibleBillSectionState();
}

class _CollapsibleBillSectionState extends State<_CollapsibleBillSection>
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
                  '${GovernmentLevelHelper.getLevelDisplayName(widget.level)} Bills',
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
                    '${widget.bills.length}',
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
            children: widget.bills.map((bill) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BillCard(
                bill: bill,
                onTap: () => widget.onBillTap(bill),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}