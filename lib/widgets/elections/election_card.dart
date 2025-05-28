import 'package:flutter/material.dart';
import 'package:govvy/models/election_model.dart';
import 'package:intl/intl.dart';

enum ElectionCardMode {
  compact,
  standard,
  detailed
}

class ElectionCard extends StatelessWidget {
  final Election election;
  final VoidCallback? onTap;
  final ElectionCardMode mode;
  final bool showLocation;
  final bool showRipple;

  const ElectionCard({
    Key? key,
    required this.election,
    this.onTap,
    this.mode = ElectionCardMode.standard,
    this.showLocation = true,
    this.showRipple = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildDate(context),
              if (mode != ElectionCardMode.compact) ...[
                const SizedBox(height: 8),
                _buildDescription(context),
              ],
              if (showLocation) ...[
                const SizedBox(height: 8),
                _buildLocation(context),
              ],
              if (mode == ElectionCardMode.detailed) ...[
                const SizedBox(height: 12),
                _buildContests(context),
              ],
              if (election.isUpcoming) ...[
                const SizedBox(height: 8),
                _buildCountdown(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getElectionIcon(),
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            election.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: mode == ElectionCardMode.compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusChip(context),
      ],
    );
  }

  Widget _buildDate(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeUntil = _getTimeUntilElection();
    
    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(election.electionDate),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (timeUntil.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: election.isUpcoming ? Colors.green[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timeUntil,
              style: TextStyle(
                fontSize: 12,
                color: election.isUpcoming ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (election.description.isEmpty) return const SizedBox.shrink();
    
    return Text(
      election.description,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: mode == ElectionCardMode.compact ? 1 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${election.city}, ${election.state}${election.county.isNotEmpty ? ' • ${election.county}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContests(BuildContext context) {
    if (election.contests.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contests (${election.contests.length})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: election.contests.take(3).map((contest) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              contest.office,
              style: const TextStyle(fontSize: 12),
            ),
          )).toList(),
        ),
        if (election.contests.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${election.contests.length - 3} more',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountdown(BuildContext context) {
    if (!election.isUpcoming) return const SizedBox.shrink();
    
    final days = election.daysUntilElection;
    final countdownText = days == 0 
        ? 'Today!'
        : days == 1 
            ? 'Tomorrow'
            : '$days days away';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: days <= 7 ? Colors.orange[100] : Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: days <= 7 ? Colors.orange[300]! : Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            days <= 7 ? Icons.schedule : Icons.event,
            size: 14,
            color: days <= 7 ? Colors.orange[700] : Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            countdownText,
            style: TextStyle(
              fontSize: 12,
              color: days <= 7 ? Colors.orange[700] : Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    Color textColor;
    
    switch (election.status.toLowerCase()) {
      case 'scheduled':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case 'active':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case 'completed':
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        break;
      case 'cancelled':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        election.status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  IconData _getElectionIcon() {
    switch (election.electionType.toLowerCase()) {
      case 'general':
        return Icons.how_to_vote;
      case 'primary':
        return Icons.ballot;
      case 'municipal':
        return Icons.location_city;
      case 'special':
        return Icons.star;
      default:
        return Icons.how_to_vote_outlined;
    }
  }

  String _getTimeUntilElection() {
    if (election.isToday) return 'Today';
    if (election.isPast) return 'Past';
    
    final days = election.daysUntilElection;
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return '$days days';
    if (days <= 30) return '${(days / 7).round()} weeks';
    if (days <= 365) return '${(days / 30).round()} months';
    
    return '';
  }
}