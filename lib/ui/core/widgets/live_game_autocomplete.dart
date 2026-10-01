import 'dart:async';
import 'package:flutter/material.dart';

/// Search suggestions from the live USA catalog, with stable input ownership.
class LiveGameAutocomplete extends StatefulWidget {
  const LiveGameAutocomplete({
    super.key,
    required this.controller,
    required this.hintText,
    required this.suggestions,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String hintText;
  final Future<List<String>> Function(String) suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onSelected;

  @override
  State<LiveGameAutocomplete> createState() => _LiveGameAutocompleteState();
}

class _LiveGameAutocompleteState extends State<LiveGameAutocomplete> {
  final FocusNode _focus = FocusNode();
  int _request = 0;
  String? _error;

  @override
  void dispose() {
    _request++;
    _focus.dispose();
    super.dispose();
  }

  Future<Iterable<String>> _options(TextEditingValue value) async {
    final query = value.text.trim();
    final request = ++_request;
    if (query.length < 3) {
      if (_error != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && request == _request) {
            setState(() => _error = null);
          }
        });
      }
      return const [];
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted ||
        request != _request ||
        widget.controller.text.trim() != query) {
      return const [];
    }
    try {
      final titles = await widget.suggestions(query);
      if (!mounted ||
          request != _request ||
          widget.controller.text.trim() != query) {
        return const [];
      }
      if (_error != null) setState(() => _error = null);
      return titles;
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error =
            'No se pudieron cargar sugerencias. Puedes buscar el título igualmente.');
      }
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focus,
          displayStringForOption: (title) => title,
          optionsBuilder: _options,
          onSelected: widget.onSelected,
          fieldViewBuilder: (_, controller, focus, onFieldSubmitted) =>
              TextField(
            controller: controller,
            focusNode: focus,
            onChanged: widget.onChanged,
            onSubmitted: (query) => widget.onSubmitted(query),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      widget.onChanged('');
                    })),
          ),
          optionsViewBuilder: (_, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 24,
                height: (options.length * 48.0).clamp(48.0, 320.0),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (_, index) {
                    final title = options.elementAt(index);
                    return ListTile(
                        dense: true,
                        title: Text(title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => onSelected(title));
                  },
                ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: const TextStyle(fontSize: 11))),
      ]);
}
