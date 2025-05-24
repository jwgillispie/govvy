# Bill Feature Enhancement Integration Guide

This guide explains how to integrate the enhanced bill search feature into your Govvy application.

## Overview

The enhanced bill feature implements a more robust search and display system for legislative bills using the LegiScan API. The implementation includes:

1. Better caching with TTL (time to live) support
2. Optimized API usage with proper endpoint selection
3. Enhanced error handling with typed exceptions
4. Improved UI components for search and display
5. Multiple search types (state, subject, keyword, sponsor)

## Integration Steps

### 1. Update Dependencies in pubspec.yaml

Ensure you have these dependencies:

```yaml
dependencies:
  intl: ^0.18.0  # For date formatting
```

### 2. Register the Enhanced Provider

In your `main.dart` file, add the enhanced bill provider:

```dart
import 'package:govvy/providers/enhanced_bill_provider.dart';

// In your main() function, update MultiProvider:
runApp(
  MultiProvider(
    providers: [
      // Other providers...
      ChangeNotifierProvider<EnhancedBillProvider>(
        create: (_) => EnhancedBillProvider(),
      ),
    ],
    child: MyApp(),
  ),
);
```

### 3. Update Navigation Routes

Add the enhanced bill screen to your navigation system. For example, in your router:

```dart
import 'package:govvy/screens/bills/enhanced_bill_screen.dart';

// In your route definition:
'/bills': (context) => const EnhancedBillScreen(),
```

### 4. Update Home Screen Navigation

Update any buttons or menu items that navigate to the bills screen:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/bills');
  },
  child: const Text('Find Bills'),
),
```

### 5. Initialize Services

Make sure to initialize the enhanced services when your app starts:

```dart
// In your app initialization:
final enhancedLegiscanService = EnhancedLegiscanService();
await enhancedLegiscanService.initialize();
```

## Modifying Existing Code

### If keeping the old implementation alongside the new one:

1. Make sure both providers don't conflict
2. Consider using a feature flag to toggle between implementations

### If replacing the old implementation:

1. Replace imports of `BillProvider` with `EnhancedBillProvider`
2. Replace imports of `BillScreen` with `EnhancedBillScreen`
3. Replace `BillCard` with `EnhancedBillCard`
4. Update consumers of the bill provider to use the new methods

## API Integration Notes

### Optimized LegiScan API Usage

The enhanced implementation makes smarter use of the LegiScan API:

1. **Session Management**: Gets and caches session information for states
2. **Master List**: Uses getMasterList for efficient bill retrieval
3. **Search Optimization**: Uses proper query parameters for subject/keyword searches
4. **Caching**: Implements TTL-based caching for different API operations

### Error Handling

The enhanced implementation provides better error handling:

1. Typed exceptions for different error cases
2. User-friendly error messages
3. Retry logic for network issues

## UI Improvements

1. **Enhanced Search**: Tabbed interface for different search types
2. **Bill Cards**: Multiple display modes (compact, standard, detailed)
3. **State Management**: Better loading/error/empty state handling

## Testing 

When testing the implementation:

1. Verify all search types work correctly
2. Test offline behavior with cached data
3. Verify error handling for API failures
4. Test with rate-limited API usage

## Known Limitations

1. LegiScan API has rate limits - be aware when testing
2. Some API endpoints require special handling (FL/GA states)
3. Historical data may have gaps or inconsistencies