// lib/utils/data_source_attribution.dart
import 'package:flutter/material.dart';

enum DataSource {
  congress,
  cicero,
  legiscan,
  fec,
  followTheMoney,
  propublica,
  census,
  ballotpedia,
  csv,
  mock,
}

class DataSourceInfo {
  final String name;
  final String description;
  final String? url;
  final Color color;
  final IconData icon;

  const DataSourceInfo({
    required this.name,
    required this.description,
    this.url,
    required this.color,
    required this.icon,
  });
}

class DataSourceAttribution {
  static const Map<DataSource, DataSourceInfo> _sourceInfo = {
    DataSource.congress: DataSourceInfo(
      name: 'Congress.gov',
      description: 'Official U.S. Congress legislative data',
      url: 'https://congress.gov',
      color: Colors.blue,
      icon: Icons.account_balance,
    ),
    DataSource.cicero: DataSourceInfo(
      name: 'Cicero API',
      description: 'Local and state government officials',
      url: 'https://cicero.azavea.com',
      color: Colors.green,
      icon: Icons.location_city,
    ),
    DataSource.legiscan: DataSourceInfo(
      name: 'LegiScan',
      description: 'State and local legislation tracking',
      url: 'https://legiscan.com',
      color: Colors.purple,
      icon: Icons.gavel,
    ),
    DataSource.fec: DataSourceInfo(
      name: 'FEC.gov',
      description: 'Federal Election Commission campaign finance data',
      url: 'https://fec.gov',
      color: Colors.red,
      icon: Icons.account_balance_wallet,
    ),
    DataSource.followTheMoney: DataSourceInfo(
      name: 'FollowTheMoney.org',
      description: 'State-level campaign finance data',
      url: 'https://followthemoney.org',
      color: Colors.orange,
      icon: Icons.monetization_on,
    ),
    DataSource.propublica: DataSourceInfo(
      name: 'ProPublica',
      description: 'Congressional voting records and data',
      url: 'https://propublica.org',
      color: Colors.indigo,
      icon: Icons.how_to_vote,
    ),
    DataSource.census: DataSourceInfo(
      name: 'U.S. Census',
      description: 'Demographic and geographic data',
      url: 'https://census.gov',
      color: Colors.teal,
      icon: Icons.people,
    ),
    DataSource.ballotpedia: DataSourceInfo(
      name: 'Ballotpedia',
      description: 'Election and candidate information',
      url: 'https://ballotpedia.org',
      color: Colors.amber,
      icon: Icons.ballot,
    ),
    DataSource.csv: DataSourceInfo(
      name: 'CSV Data',
      description: 'Curated local government data',
      color: Colors.grey,
      icon: Icons.storage,
    ),
    DataSource.mock: DataSourceInfo(
      name: 'Demo Data',
      description: 'Sample data for demonstration',
      color: Colors.grey,
      icon: Icons.science,
    ),
  };

  static DataSourceInfo getSourceInfo(DataSource source) {
    return _sourceInfo[source]!;
  }

  static Widget buildSourceBadge(
    DataSource source, {
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showText = true,
    bool compact = false,
  }) {
    final info = getSourceInfo(source);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == BadgeSize.small ? 4 : (compact ? 6 : 8),
        vertical: size == BadgeSize.small ? 2 : (compact ? 2 : 4),
      ),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size == BadgeSize.small ? 3 : 4),
        border: Border.all(
          color: info.color.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              info.icon,
              size: size == BadgeSize.small ? 10 : (compact ? 12 : 14),
              color: info.color,
            ),
            if (showText && !compact) const SizedBox(width: 3),
            if (showText && compact) const SizedBox(width: 2),
          ],
          if (showText)
            Text(
              info.name,
              style: TextStyle(
                fontSize: size == BadgeSize.small ? 9 : (compact ? 10 : 11),
                fontWeight: FontWeight.w600,
                color: info.color,
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildSourceAttribution(
    List<DataSource> sources, {
    String? prefix,
    MainAxisAlignment alignment = MainAxisAlignment.start,
    bool wrap = false,
  }) {
    if (sources.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    
    if (prefix != null) {
      widgets.add(
        Text(
          prefix,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      );
      widgets.add(const SizedBox(width: 4));
    }

    for (int i = 0; i < sources.length; i++) {
      widgets.add(
        buildSourceBadge(
          sources[i],
          size: BadgeSize.small,
          compact: true,
        ),
      );
      
      if (i < sources.length - 1) {
        widgets.add(const SizedBox(width: 4));
      }
    }

    if (wrap) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.start,
        children: widgets,
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  static Widget buildDetailedSourceInfo(
    DataSource source, {
    bool showDescription = true,
    bool showUrl = true,
  }) {
    final info = getSourceInfo(source);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: info.color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.icon,
                size: 18,
                color: info.color,
              ),
              const SizedBox(width: 8),
              Text(
                info.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: info.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 4),
            Text(
              info.description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          if (showUrl && info.url != null) ...[
            const SizedBox(height: 4),
            Text(
              info.url!,
              style: TextStyle(
                fontSize: 11,
                color: info.color,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static DataSource detectSourceFromBioGuideId(String? bioGuideId) {
    if (bioGuideId == null || bioGuideId.isEmpty) {
      return DataSource.mock;
    }

    if (bioGuideId.startsWith('cicero-')) {
      return DataSource.cicero;
    } else if (bioGuideId.length > 3 && !bioGuideId.startsWith('cicero-')) {
      // Congress.gov bioGuideIds are typically short alphanumeric codes
      return DataSource.congress;
    } else {
      return DataSource.mock;
    }
  }

  static DataSource detectSourceFromBillData(dynamic bill) {
    if (bill == null) return DataSource.mock;
    
    // Check bill type field (this is more reliable than source field which doesn't exist)
    final type = bill.type?.toString().toLowerCase() ?? '';
    if (type == 'federal') {
      return DataSource.congress;
    } else if (type == 'local') {
      return DataSource.csv;
    }
    
    // Check URL patterns for more specific detection
    final url = bill.url?.toString() ?? '';
    if (url.contains('congress.gov')) {
      return DataSource.congress;
    } else if (url.contains('legiscan.com')) {
      return DataSource.legiscan;
    }
    
    // Check bill ID patterns
    final billId = bill.billId?.toString() ?? '';
    if (billId.contains('legiscan')) {
      return DataSource.legiscan;
    } else if (billId.contains('congress')) {
      return DataSource.congress;
    }
    
    // Default based on state and type
    final state = bill.state?.toString() ?? '';
    if (state == 'US' || state.isEmpty) {
      return DataSource.congress;
    } else if (type == 'state') {
      return DataSource.legiscan;
    } else {
      // Default to LegiScan for state/local bills
      return DataSource.legiscan;
    }
  }

  static List<DataSource> getFinanceDataSources(dynamic candidate) {
    final sources = <DataSource>[];
    
    // Check for FEC candidate ID (the actual property name)
    if (candidate?.candidateId != null && candidate.candidateId.isNotEmpty) {
      sources.add(DataSource.fec);
    }
    
    // Check for Follow the Money ID (if it exists in the future)
    if (candidate?.followTheMoneyId != null) {
      sources.add(DataSource.followTheMoney);
    }
    
    return sources.isEmpty ? [DataSource.mock] : sources;
  }
}

enum BadgeSize { small, medium, large }