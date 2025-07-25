// lib/utils/navigation_helper.dart
import 'package:flutter/material.dart';
import 'package:govvy/screens/bills/enhanced_bill_screen.dart';
import 'package:govvy/screens/representatives/representative_details_screen.dart';
import 'package:govvy/screens/bills/bill_details_screen.dart';
import 'package:govvy/screens/representatives/find_representatives_screen.dart';
import 'package:govvy/screens/candidates/candidate_profile_screen.dart';
import 'package:govvy/providers/bill_provider.dart';
import 'package:govvy/providers/enhanced_bill_provider.dart';
import 'package:govvy/providers/combined_representative_provider.dart';
import 'package:provider/provider.dart';

/// Helper class to navigate between bills and representative screens
class NavigationHelper {
  /// Navigate to a specific representative's details
  static void navigateToRepresentativeDetails(BuildContext context, String bioGuideId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepresentativeDetailsScreen(
          bioGuideId: bioGuideId,
        ),
      ),
    );
  }
  
  /// Navigate to a specific bill's details
  static void navigateToBillDetails(BuildContext context, int billId, String stateCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillDetailsScreen(
          billId: billId,
          stateCode: stateCode,
        ),
      ),
    );
  }
  
  /// Navigate to the enhanced bill search screen
  static void navigateToEnhancedBillScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedBillScreen(),
      ),
    );
  }
  
  /// Navigate to bills by subject using the enhanced provider
  static void navigateToBillsBySubject(
    BuildContext context, 
    String subject, 
    {String? stateCode}
  ) {
    final enhancedBillProvider = Provider.of<EnhancedBillProvider>(context, listen: false);
    enhancedBillProvider.searchBillsBySubject(subject, stateCode: stateCode);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedBillScreen(),
      ),
    );
  }
  
  /// Navigate to bills sponsored by a representative
  static void navigateToBillsByRepresentative(
    BuildContext context, 
    String bioGuideId, 
    String name, 
    String state
  ) {
    // First fetch the representative details to get complete info
    final repProvider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
    repProvider.fetchRepresentativeDetails(bioGuideId).then((_) {
      final representative = repProvider.selectedRepresentative;
      
      if (representative != null && context.mounted) {
        final enhancedBillProvider = Provider.of<EnhancedBillProvider>(context, listen: false);
        
        // Our enhanced provider now supports both types directly
        enhancedBillProvider.fetchBillsByRepresentative(representative);
        
        // Navigate to the enhanced bill screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EnhancedBillScreen(),
          ),
        );
      }
    });
  }
  
  /// Navigate to a candidate profile screen
  static void navigateToCandidateProfile(
    BuildContext context, 
    String candidateName, {
    String? candidateId,
    String? office,
    String? party,
    String? state,
    String? district,
    int? cycle,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateProfileScreen(
          candidateName: candidateName,
          candidateId: candidateId,
          office: office,
          party: party,
          state: state,
          district: district,
          cycle: cycle,
        ),
      ),
    );
  }
  
  /// Navigate to representatives who sponsored a bill
  static void navigateToRepresentativesByBill(
    BuildContext context, 
    int billId, 
    String stateCode
  ) {
    // First fetch the bill details to get sponsor info
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    billProvider.fetchBillDetails(billId, stateCode).then((_) {
      final bill = billProvider.selectedBill;
      
      if (bill != null && bill.sponsors != null && bill.sponsors!.isNotEmpty) {
        // Get the first sponsor with a bioGuideId
        final sponsor = bill.sponsors!.firstWhere(
          (s) => s.bioGuideId != null,
          orElse: () => bill.sponsors!.first,
        );
        
        if (sponsor.bioGuideId != null) {
          // Navigate to the representative details
          if (context.mounted) {
            navigateToRepresentativeDetails(context, sponsor.bioGuideId!);
          }
        } else {
          // If no bioGuideId available, search by name
          if (context.mounted) {
            final repProvider = Provider.of<CombinedRepresentativeProvider>(context, listen: false);
            repProvider.fetchRepresentativesByName(
              sponsor.name.split(' ').last, // Use last name
              firstName: sponsor.name.split(' ').first, // Use first name
            );
            
            // Navigate to find representatives screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FindRepresentativesScreen(),
              ),
            );
          }
        }
      }
    });
  }
}