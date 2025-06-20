import 'package:flutter/material.dart';
import 'package:govvy/utils/us_states_data.dart';

class StateDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? hintText;
  final bool includeAllOption;
  final String allOptionText;
  final bool includeTerritoriesAndDC;
  final InputDecoration? decoration;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final TextStyle? style;
  final bool isExpanded;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  const StateDropdown({
    Key? key,
    this.value,
    required this.onChanged,
    this.hintText,
    this.includeAllOption = false,
    this.allOptionText = 'All States',
    this.includeTerritoriesAndDC = true,
    this.decoration,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.style,
    this.isExpanded = true,
    this.focusNode,
    this.validator,
    this.autovalidateMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get the appropriate list of states
    final statesList = includeTerritoriesAndDC 
        ? USStatesData.sortedByName 
        : USStatesData.statesOnly..sort((a, b) => a["name"]!.compareTo(b["name"]!));

    // Build dropdown items
    final items = <DropdownMenuItem<String>>[];
    
    // Add "All" option if requested
    if (includeAllOption) {
      items.add(
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            allOptionText,
            style: style?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    
    // Add state items
    items.addAll(
      statesList.map((state) {
        return DropdownMenuItem<String>(
          value: state["code"],
          child: Text(
            '${state["name"]} (${state["code"]})',
            style: style,
          ),
        );
      }),
    );

    final effectiveDecoration = decoration ?? InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: hintText ?? 'Select a state',
      prefixIcon: prefix,
      suffixIcon: suffix,
    );

    return DropdownButtonFormField<String>(
      value: value,
      onChanged: enabled ? onChanged : null,
      items: items,
      decoration: effectiveDecoration,
      isExpanded: isExpanded,
      focusNode: focusNode,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: style ?? theme.textTheme.bodyLarge,
      dropdownColor: theme.colorScheme.surface,
      menuMaxHeight: 300,
    );
  }
}

class StateDropdownFormField extends FormField<String> {
  StateDropdownFormField({
    Key? key,
    String? initialValue,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    AutovalidateMode? autovalidateMode,
    bool enabled = true,
    String? hintText,
    bool includeAllOption = false,
    String allOptionText = 'All States',
    bool includeTerritoriesAndDC = true,
    InputDecoration? decoration,
    Widget? prefix,
    Widget? suffix,
    TextStyle? style,
    bool isExpanded = true,
    FocusNode? focusNode,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue,
          autovalidateMode: autovalidateMode,
          enabled: enabled,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StateDropdown(
                  value: state.value,
                  onChanged: state.didChange,
                  hintText: hintText,
                  includeAllOption: includeAllOption,
                  allOptionText: allOptionText,
                  includeTerritoriesAndDC: includeTerritoriesAndDC,
                  decoration: decoration?.copyWith(
                    errorText: state.hasError ? state.errorText : null,
                  ),
                  enabled: enabled,
                  prefix: prefix,
                  suffix: suffix,
                  style: style,
                  isExpanded: isExpanded,
                  focusNode: focusNode,
                ),
              ],
            );
          },
        );
}

class StateMultiSelect extends StatefulWidget {
  final List<String> selectedStates;
  final ValueChanged<List<String>> onChanged;
  final String? hintText;
  final bool includeTerritoriesAndDC;
  final InputDecoration? decoration;
  final bool enabled;
  final int? maxSelections;
  final Widget? prefix;
  final Widget? suffix;

  const StateMultiSelect({
    Key? key,
    required this.selectedStates,
    required this.onChanged,
    this.hintText,
    this.includeTerritoriesAndDC = true,
    this.decoration,
    this.enabled = true,
    this.maxSelections,
    this.prefix,
    this.suffix,
  }) : super(key: key);

  @override
  State<StateMultiSelect> createState() => _StateMultiSelectState();
}

class _StateMultiSelectState extends State<StateMultiSelect> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final statesList = widget.includeTerritoriesAndDC 
        ? USStatesData.sortedByName 
        : USStatesData.statesOnly..sort((a, b) => a["name"]!.compareTo(b["name"]!));

    final effectiveDecoration = widget.decoration ?? InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: widget.hintText ?? 'Select states',
      prefixIcon: widget.prefix,
      suffixIcon: widget.suffix,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected states display
        Container(
          decoration: effectiveDecoration.border != null 
              ? BoxDecoration(
                  color: effectiveDecoration.fillColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.prefix != null) ...[
                widget.prefix!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: widget.selectedStates.isEmpty
                    ? Text(
                        widget.hintText ?? 'Select states',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.selectedStates.map((stateCode) {
                          return Chip(
                            label: Text(stateCode),
                            onDeleted: widget.enabled 
                                ? () {
                                    final newSelection = List<String>.from(widget.selectedStates);
                                    newSelection.remove(stateCode);
                                    widget.onChanged(newSelection);
                                  }
                                : null,
                            deleteIconColor: theme.colorScheme.onSurfaceVariant,
                          );
                        }).toList(),
                      ),
              ),
              IconButton(
                onPressed: widget.enabled 
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Expandable state selection
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: statesList.length,
              itemBuilder: (context, index) {
                final state = statesList[index];
                final stateCode = state["code"]!;
                final stateName = state["name"]!;
                final isSelected = widget.selectedStates.contains(stateCode);
                final canSelect = widget.maxSelections == null || 
                    widget.selectedStates.length < widget.maxSelections! ||
                    isSelected;

                return CheckboxListTile(
                  title: Text('$stateName ($stateCode)'),
                  value: isSelected,
                  onChanged: widget.enabled && canSelect
                      ? (bool? value) {
                          final newSelection = List<String>.from(widget.selectedStates);
                          if (value == true) {
                            newSelection.add(stateCode);
                          } else {
                            newSelection.remove(stateCode);
                          }
                          widget.onChanged(newSelection);
                        }
                      : null,
                  dense: true,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}