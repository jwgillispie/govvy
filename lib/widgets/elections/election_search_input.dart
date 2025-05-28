import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:govvy/providers/election_provider.dart';
import 'package:govvy/screens/elections/election_screen.dart';

class ElectionSearchInput extends StatefulWidget {
  final VoidCallback onSearch;
  final ElectionSearchType searchType;
  final Function(ElectionSearchType) onSearchTypeChanged;
  final String? selectedState;
  final String? selectedCity;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool upcomingOnly;
  final Function(String?) onStateChanged;
  final Function(String?) onCityChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(bool) onUpcomingOnlyChanged;

  const ElectionSearchInput({
    Key? key,
    required this.onSearch,
    required this.searchType,
    required this.onSearchTypeChanged,
    this.selectedState,
    this.selectedCity,
    this.startDate,
    this.endDate,
    required this.upcomingOnly,
    required this.onStateChanged,
    required this.onCityChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onUpcomingOnlyChanged,
  }) : super(key: key);

  @override
  State<ElectionSearchInput> createState() => _ElectionSearchInputState();
}

class _ElectionSearchInputState extends State<ElectionSearchInput> {
  final List<Map<String, String>> _usStates = [
    {"name": "Alabama", "code": "AL"},
    {"name": "Alaska", "code": "AK"},
    {"name": "Arizona", "code": "AZ"},
    {"name": "Arkansas", "code": "AR"},
    {"name": "California", "code": "CA"},
    {"name": "Colorado", "code": "CO"},
    {"name": "Connecticut", "code": "CT"},
    {"name": "Delaware", "code": "DE"},
    {"name": "Florida", "code": "FL"},
    {"name": "Georgia", "code": "GA"},
    {"name": "Hawaii", "code": "HI"},
    {"name": "Idaho", "code": "ID"},
    {"name": "Illinois", "code": "IL"},
    {"name": "Indiana", "code": "IN"},
    {"name": "Iowa", "code": "IA"},
    {"name": "Kansas", "code": "KS"},
    {"name": "Kentucky", "code": "KY"},
    {"name": "Louisiana", "code": "LA"},
    {"name": "Maine", "code": "ME"},
    {"name": "Maryland", "code": "MD"},
    {"name": "Massachusetts", "code": "MA"},
    {"name": "Michigan", "code": "MI"},
    {"name": "Minnesota", "code": "MN"},
    {"name": "Mississippi", "code": "MS"},
    {"name": "Missouri", "code": "MO"},
    {"name": "Montana", "code": "MT"},
    {"name": "Nebraska", "code": "NE"},
    {"name": "Nevada", "code": "NV"},
    {"name": "New Hampshire", "code": "NH"},
    {"name": "New Jersey", "code": "NJ"},
    {"name": "New Mexico", "code": "NM"},
    {"name": "New York", "code": "NY"},
    {"name": "North Carolina", "code": "NC"},
    {"name": "North Dakota", "code": "ND"},
    {"name": "Ohio", "code": "OH"},
    {"name": "Oklahoma", "code": "OK"},
    {"name": "Oregon", "code": "OR"},
    {"name": "Pennsylvania", "code": "PA"},
    {"name": "Rhode Island", "code": "RI"},
    {"name": "South Carolina", "code": "SC"},
    {"name": "South Dakota", "code": "SD"},
    {"name": "Tennessee", "code": "TN"},
    {"name": "Texas", "code": "TX"},
    {"name": "Utah", "code": "UT"},
    {"name": "Vermont", "code": "VT"},
    {"name": "Virginia", "code": "VA"},
    {"name": "Washington", "code": "WA"},
    {"name": "West Virginia", "code": "WV"},
    {"name": "Wisconsin", "code": "WI"},
    {"name": "Wyoming", "code": "WY"},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Elections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSearchTypeSelector(),
            const SizedBox(height: 16),
            _buildSearchInputs(),
            const SizedBox(height: 16),
            _buildSearchButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ElectionSearchType>(
          segments: const [
            ButtonSegment(
              value: ElectionSearchType.location,
              label: Text('Location'),
              icon: Icon(Icons.location_on),
            ),
            ButtonSegment(
              value: ElectionSearchType.upcoming,
              label: Text('Upcoming'),
              icon: Icon(Icons.schedule),
            ),
            ButtonSegment(
              value: ElectionSearchType.dateRange,
              label: Text('Date Range'),
              icon: Icon(Icons.date_range),
            ),
          ],
          selected: {widget.searchType},
          onSelectionChanged: (selection) {
            widget.onSearchTypeChanged(selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildSearchInputs() {
    switch (widget.searchType) {
      case ElectionSearchType.location:
        return _buildLocationInputs();
      case ElectionSearchType.upcoming:
        return _buildUpcomingInputs();
      case ElectionSearchType.dateRange:
        return _buildDateRangeInputs();
    }
  }

  Widget _buildLocationInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStateDropdown(),
        const SizedBox(height: 16),
        _buildCityDropdown(),
        const SizedBox(height: 16),
        _buildUpcomingOnlyCheckbox(),
      ],
    );
  }

  Widget _buildUpcomingInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStateDropdown(),
        const SizedBox(height: 16),
        Text(
          'Show all upcoming elections${widget.selectedState != null ? ' in ${widget.selectedState}' : ' nationwide'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStateDropdown(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePicker('Start Date', widget.startDate, widget.onStartDateChanged)),
            const SizedBox(width: 16),
            Expanded(child: _buildDatePicker('End Date', widget.endDate, widget.onEndDateChanged)),
          ],
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Consumer<ElectionProvider>(
          builder: (context, provider, child) {
            return DropdownButtonFormField<String>(
              value: widget.selectedState,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a state (optional)',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All States'),
                ),
                ..._usStates.map((state) => DropdownMenuItem<String>(
                  value: state['code'],
                  child: Text('${state['name']} (${state['code']})'),
                )),
              ],
              onChanged: widget.onStateChanged,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Consumer<ElectionProvider>(
          builder: (context, provider, child) {
            if (widget.selectedState == null) {
              return const TextField(
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a state first',
                ),
              );
            }

            if (provider.isLoadingCities) {
              return const TextField(
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Loading cities...',
                ),
              );
            }

            return DropdownButtonFormField<String>(
              value: widget.selectedCity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a city (optional)',
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Cities'),
                ),
                ...provider.citiesInState.map((city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                )),
              ],
              onChanged: widget.onCityChanged,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365 * 4)),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null 
                        ? '${date.month}/${date.day}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: date != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingOnlyCheckbox() {
    return CheckboxListTile(
      title: const Text('Upcoming elections only'),
      subtitle: const Text('Show only elections that have not yet occurred'),
      value: widget.upcomingOnly,
      onChanged: (value) => widget.onUpcomingOnlyChanged(value ?? true),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      child: Consumer<ElectionProvider>(
        builder: (context, provider, child) {
          return ElevatedButton.icon(
            onPressed: provider.isLoading ? null : widget.onSearch,
            icon: provider.isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(provider.isLoading ? 'Searching...' : 'Search Elections'),
          );
        },
      ),
    );
  }
}