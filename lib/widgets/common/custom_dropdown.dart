// Create this file in lib/widgets/common/custom_dropdown.dart

import 'package:flutter/material.dart';
import '../../config/constants.dart';

class CustomDropdown extends StatelessWidget {
  final String? labelText;
  final String hintText;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool isSearchable;
 final bool disabled; // Add this parameter
  const CustomDropdown({
    Key? key,
    this.labelText,
    required this.hintText,
    this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isSearchable = false,
    this.disabled = false, // Default to enabled
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              labelText!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        if (isSearchable)
          _buildSearchableDropdown(context)
        else
          _buildSimpleDropdown(),
      ],
    );
  }

  Widget _buildSimpleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
         color: disabled ? Colors.grey.shade200 : Colors.white, // Grayed out if disabled
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          hintText,
          style: const TextStyle(color: Colors.grey),
        ),
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: validator,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
         onChanged: disabled ? null : onChanged, // Set to null when disabled
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
        dropdownColor: Colors.white,
      ),
    );
  }

 Widget _buildSearchableDropdown(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: disabled ? Colors.grey.shade200 : Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: FormField<String>(
      validator: validator,
      initialValue: value,
      builder: (FormFieldState<String> state) {
        return InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            border: InputBorder.none,
            errorText: state.hasError ? state.errorText : null,
          ),
          isEmpty: value == null || value!.isEmpty,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              hint: Text(
                hintText,
                style: TextStyle(color: disabled ? Colors.grey.shade500 : Colors.grey),
              ),
              onChanged: disabled ? null : (String? newValue) {
                onChanged(newValue);
                state.didChange(newValue);
              },
              onTap: disabled ? null : () {
                _showSearchDialog(context, state);
              },
              items: [
                if (value != null)
                  DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value!,
                      style: TextStyle(
                        fontSize: 14,
                        color: disabled ? Colors.grey.shade500 : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  void _showSearchDialog(BuildContext context, FormFieldState<String> state) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        List<String> filteredItems = items;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(labelText ?? 'Select $hintText'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                          filteredItems = items
                              .where((item) => item.toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            title: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              onChanged(item);
                              state.didChange(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}