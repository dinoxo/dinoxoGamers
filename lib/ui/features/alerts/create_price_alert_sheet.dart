import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_edition.dart';
import '../../../domain/models/user_alert.dart';
import '../../../domain/services/notification_service.dart';

double? parseAlertPrice(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d{1,5}(?:[.,]\d{0,2})?$').hasMatch(text)) return null;
  final price = double.tryParse(text.replaceAll(',', '.'));
  return price != null && price.isFinite && price >= 0
      ? (price * 100).round() / 100
      : null;
}

class CreatePriceAlertSheet extends StatefulWidget {
  const CreatePriceAlertSheet(
      {super.key,
      required this.game,
      required this.edition,
      required this.repository,
      this.requestPermission});
  final Game game;
  final GameEdition edition;
  final GameRepository repository;
  final Future<bool> Function()? requestPermission;
  @override
  State<CreatePriceAlertSheet> createState() => _CreatePriceAlertSheetState();
}

class _CreatePriceAlertSheetState extends State<CreatePriceAlertSheet> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(
      text: (widget.edition.currentPrice * .85).toStringAsFixed(2));
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final alert = UserAlert(
          id: now.microsecondsSinceEpoch.toString(),
          gameId: widget.game.id,
          editionId: widget.edition.id,
          gameTitle: widget.game.title,
          platform: widget.game.platform,
          editionName: widget.edition.name,
          targetPrice: parseAlertPrice(_price.text)!,
          alertOnAllTimeLow: false,
          alertOnPromoEnding: false,
          createdAt: now);
      await widget.repository.saveAlert(alert);
      final permission = await (widget.requestPermission ??
          NotificationService.instance.requestPermission)();
      // Query the source once immediately; future revisions are scheduled in Android.
      unawaited(
          widget.repository.refreshAlertPrices().catchError((_) => <String>[]));
      if (mounted) {
        Navigator.pop(
            context,
            permission
                ? 'Alerta guardada. Te avisaremos al comprobar un precio igual o menor a tu objetivo.'
                : 'Alerta guardada. Activa las notificaciones en Mis Alertas o en Ajustes del teléfono para recibir avisos.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar la alerta. Reintenta.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Text('Crear Alerta de Precio',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ]),
                    Text('${widget.game.title} · ${widget.edition.name}'),
                    const SizedBox(height: 16),
                    TextFormField(
                        key: const Key('alert-target-price'),
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Precio objetivo (USD)',
                            prefixText: '\$ ',
                            hintText: 'Ej. 9,99'),
                        validator: (text) => parseAlertPrice(text ?? '') == null
                            ? 'Introduce un importe desde 0 con hasta 2 decimales.'
                            : null,
                        onChanged: (_) => setState(() {})),
                    if (widget.edition.currentPrice > 0)
                      Slider(
                          value: (parseAlertPrice(_price.text) ?? 0)
                              .clamp(0, widget.edition.currentPrice),
                          min: 0,
                          max: widget.edition.currentPrice,
                          divisions: 100,
                          onChanged: _saving
                              ? null
                              : (price) => setState(() =>
                                  _price.text = price.toStringAsFixed(2))),
                    Text(
                        'Avisar a ${CurrencyFormatter.formatUsd(parseAlertPrice(_price.text) ?? 0)} USD o menos.'),
                    const SizedBox(height: 12),
                    const Text(
                        'Android revisará las alertas con conexión en intervalos de aproximadamente 15 minutos. Puede retrasarlas para ahorrar batería. Se respeta el silencio de 22:00 a 08:00.'),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Guardando…' : 'Guardar Alerta')),
                  ]))));
}
