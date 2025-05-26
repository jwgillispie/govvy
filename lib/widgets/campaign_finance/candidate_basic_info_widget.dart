import 'package:flutter/material.dart';
import 'package:govvy/models/campaign_finance_model.dart';

class CandidateBasicInfoWidget extends StatelessWidget {
  final FECCandidate candidate;

  const CandidateBasicInfoWidget({
    super.key,
    required this.candidate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Candidate Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Name', candidate.name),
            if (candidate.party != null)
              _buildInfoRow('Party', _getPartyDisplayName(candidate.party!)),
            if (candidate.office != null)
              _buildInfoRow('Office', _getOfficeDisplayName(candidate.office!)),
            if (candidate.electionYear != null)
              _buildInfoRow('Election Year', candidate.electionYear.toString()),
            if (candidate.state != null)
              _buildInfoRow('State', candidate.state!),
            if (candidate.district != null && candidate.district != '00')
              _buildInfoRow('District', candidate.district!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getPartyDisplayName(String party) {
    switch (party.toUpperCase()) {
      case 'DEM':
        return 'Democratic';
      case 'REP':
        return 'Republican';
      case 'IND':
        return 'Independent';
      case 'LIB':
        return 'Libertarian';
      case 'GRN':
        return 'Green';
      default:
        return party;
    }
  }

  String _getOfficeDisplayName(String office) {
    switch (office.toUpperCase()) {
      case 'P':
        return 'President';
      case 'S':
        return 'Senate';
      case 'H':
        return 'House of Representatives';
      default:
        return office;
    }
  }
}