import 'package:flutter/material.dart';
import '../../core/widgets/gaming_header.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/services/whatsapp_service.dart';
import '../../core/widgets/usa_badge.dart';

class DinoxoStoreScreen extends StatefulWidget {
  const DinoxoStoreScreen({super.key});

  @override
  State<DinoxoStoreScreen> createState() => _DinoxoStoreScreenState();
}

class _DinoxoStoreScreenState extends State<DinoxoStoreScreen> {
  GamePlatform _selectedPlatform = GamePlatform.playstation;
  int _selectedDenomination = 25;

  // Denominations list from 1 to 200
  static final List<int> _allDenominations = List.generate(200, (i) => i + 1);

  // US Tax Calculator state
  final TextEditingController _calcPriceController =
      TextEditingController(text: '49.99');
  double _taxPercent = 7.0;

  @override
  void dispose() {
    _calcPriceController.dispose();
    super.dispose();
  }

  void _onWhatsAppPressed() {
    WhatsAppService.sendGiftCardInquiry(
      platform: _selectedPlatform,
      amountUsd: _selectedDenomination,
    );
  }

  void _showDenominationPicker() {
    String modalFilter = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final modalList = _allDenominations.where((val) {
              if (modalFilter.trim().isEmpty) return true;
              return val.toString().contains(modalFilter.trim());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withAlpha(120),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Selecciona el Valor (1\$ a 200\$)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppTheme.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Search filter
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar monto (ej. 15, 25, 50, 100)...',
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppTheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          suffixIcon: modalFilter.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setModalState(() => modalFilter = ''),
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) =>
                            setModalState(() => modalFilter = val),
                      ),
                      const SizedBox(height: 10),

                      // Quick popular chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [10, 20, 30, 40, 50, 75, 100, 150, 200]
                              .map((quickVal) {
                            final isSelected =
                                _selectedDenomination == quickVal;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(
                                  '\$$quickVal',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceSubtle,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryLight
                                      : AppTheme.border,
                                ),
                                onPressed: () {
                                  setState(
                                      () => _selectedDenomination = quickVal);
                                  Navigator.pop(ctx);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // List
                      Expanded(
                        child: modalList.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay denominaciones que coincidan.',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: modalList.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: AppTheme.border, height: 1),
                                itemBuilder: (context, index) {
                                  final val = modalList[index];
                                  final isSelected =
                                      _selectedDenomination == val;

                                  return ListTile(
                                    tileColor: isSelected
                                        ? AppTheme.primary.withAlpha(35)
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    leading: Container(
                                      width: 44,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryLight
                                              : AppTheme.border,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '\$$val',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppTheme.textPrimary,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      'Gift Card de \$$val USD',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle,
                                            color: AppTheme.secondary, size: 22)
                                        : const Icon(
                                            Icons.radio_button_unchecked,
                                            color: AppTheme.textMuted,
                                            size: 20),
                                    onTap: () {
                                      setState(
                                          () => _selectedDenomination = val);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildElegantIconButton({
    IconData? icon,
    Widget? customChild,
    required Color color,
    required Gradient gradient,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withAlpha(80),
          highlightColor: color.withAlpha(40),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(160), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: customChild ?? Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculator values
    final gamePrice = double.tryParse(_calcPriceController.text) ?? 0.0;
    final taxAmount = (gamePrice * (_taxPercent / 100));
    final totalPriceWithTax = gamePrice + taxAmount;

    return Scaffold(
      appBar: GamingHeader.adaptive(
        context,
        title: 'Dinoxo Store USA',
        subtitle: 'Gift cards para tu próxima aventura. Contáctanos.',
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: UsaBadge(compact: true)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Official Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1338), Color(0xFF13192B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Official metallic DinoxoStore logo
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primaryLight, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(120),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/dinoxo_store_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront,
                              color: AppTheme.primaryLight,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.storeName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Gift Cards Digitales Oficiales · Región USA',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Atención directa y personalizada para recargar saldo oficial en PlayStation Network, Nintendo eShop y Xbox Store (USA).',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Large elegant action icons without text: WhatsApp, Web, Instagram, TikTok
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // WhatsApp direct chat
                      _buildElegantIconButton(
                        icon: Icons.chat,
                        color: const Color(0xFF25D366),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        tooltip: 'Consultar por WhatsApp (+58 426 815 8785)',
                        onTap: () => WhatsAppService.sendGeneralStoreInquiry(),
                      ),

                      // Official Website
                      _buildElegantIconButton(
                        icon: Icons.language,
                        color: const Color(0xFF3B82F6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        tooltip: 'Sitio Web Oficial (dinoxostore.com)',
                        onTap: () => WhatsAppService.launchExternalUrl(
                            AppConstants.storeWebsite),
                      ),

                      // Instagram
                      _buildElegantIconButton(
                        icon: Icons.camera_alt_outlined,
                        color: const Color(0xFFE1306C),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFFD1D1D),
                            Color(0xFFFCAF45)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        tooltip: 'Instagram Oficial (@dinoxo.store)',
                        onTap: () => WhatsAppService.launchExternalUrl(
                            AppConstants.storeInstagram),
                      ),

                      // TikTok
                      _buildElegantIconButton(
                        customChild: const TikTokLogo(size: 26),
                        color: const Color(0xFF00F2FE),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF010101), Color(0xFF161823)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        tooltip: 'TikTok Oficial (@dinoxo.store)',
                        onTap: () => WhatsAppService.launchExternalUrl(
                            AppConstants.storeTikTok),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Account Region Warning (Important requirement)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withAlpha(100)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppTheme.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aviso de Compatibilidad de Cuenta',
                          style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Estas giftcards son de región Estados Unidos (USA) en dólares (USD). Asegúrate de que la región de tu cuenta de PlayStation Network, Nintendo eShop o Microsoft Xbox esté configurada en Estados Unidos antes de canjear.',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11,
                              height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Platform Selector
            const Text(
              '1. Elige tu Consola',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('PlayStation')),
                    selected: _selectedPlatform == GamePlatform.playstation,
                    selectedColor: AppTheme.playStationColor.withAlpha(70),
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                            () => _selectedPlatform = GamePlatform.playstation);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Nintendo')),
                    selected: _selectedPlatform == GamePlatform.nintendo,
                    selectedColor: AppTheme.nintendoColor.withAlpha(70),
                    onSelected: (selected) {
                      if (selected) {
                        setState(
                            () => _selectedPlatform = GamePlatform.nintendo);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Xbox')),
                    selected: _selectedPlatform == GamePlatform.xbox,
                    selectedColor: AppTheme.xboxColor.withAlpha(70),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPlatform = GamePlatform.xbox);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Denomination Selector ($1 to $200)
            const Text(
              '2. Selecciona la Denominación (1\$ - 200\$)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            // Single elegant selector tile that opens the modal
            InkWell(
              onTap: _showDenominationPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primaryLight.withAlpha(120), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Amount badge
                    Container(
                      width: 52,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryLight),
                      ),
                      child: Center(
                        child: Text(
                          '\$$_selectedDenomination',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gift Card de \$$_selectedDenomination USD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Toca para cambiar monto (1\$ a 200\$)',
                            style: TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.secondary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick popular chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [10, 20, 50, 75, 100, 200].map((quickVal) {
                  final isSelected = _selectedDenomination == quickVal;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        '\$$quickVal',
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceSubtle,
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryLight
                            : AppTheme.border,
                      ),
                      onPressed: () {
                        setState(() => _selectedDenomination = quickVal);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // PRIMARY CTA: WhatsApp Consultation
            ElevatedButton.icon(
              onPressed: _onWhatsAppPressed,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: Text(
                'Comprar Gift Card de \$$_selectedDenomination USD por WhatsApp',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'El mensaje se abrirá en WhatsApp para que lo revises antes de enviarlo.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 26),

            // US TAX & SALDO CALCULATOR (Complementary feature)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calculate_outlined,
                          color: AppTheme.secondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Calculadora de Saldo e Impuestos USA',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'En tiendas digitales de USA, el impuesto estatal (sales tax) varía según el código postal (ZIP code) de tu cuenta (de 0% en estados como Oregón hasta ~9% en otros).',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _calcPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Precio del Juego (USD)',
                            prefixText: '\$ ',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          initialValue: _taxPercent,
                          decoration:
                              const InputDecoration(labelText: 'Tax Estimado'),
                          items: const [
                            DropdownMenuItem(
                                value: 0.0, child: Text('0% (Sin Tax)')),
                            DropdownMenuItem(value: 6.0, child: Text('6%')),
                            DropdownMenuItem(
                                value: 7.0, child: Text('7% (Promedio)')),
                            DropdownMenuItem(value: 8.5, child: Text('8.5%')),
                            DropdownMenuItem(value: 10.0, child: Text('10%')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _taxPercent = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal juego:',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11)),
                            Text(CurrencyFormatter.formatUsd(gamePrice),
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Impuesto estimado ($_taxPercent%):',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11)),
                            Text('+ ${CurrencyFormatter.formatUsd(taxAmount)}',
                                style: const TextStyle(
                                    color: AppTheme.warning, fontSize: 11)),
                          ],
                        ),
                        const Divider(color: AppTheme.border, height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total necesario en cuenta:',
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            Text(
                              CurrencyFormatter.formatUsd(totalPriceWithTax),
                              style: const TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TikTokLogo extends StatelessWidget {
  final double size;

  const TikTokLogo({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TikTokPainter(),
      ),
    );
  }
}

class _TikTokPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    Path createPath() {
      final p = Path();
      p.moveTo(12.5 * scale, 2.0 * scale);
      p.lineTo(15.5 * scale, 2.0 * scale);
      p.cubicTo(15.7 * scale, 4.0 * scale, 17.2 * scale, 6.0 * scale,
          19.5 * scale, 6.5 * scale);
      p.cubicTo(20.5 * scale, 6.7 * scale, 21.6 * scale, 6.7 * scale,
          22.5 * scale, 6.4 * scale);
      p.lineTo(22.5 * scale, 9.8 * scale);
      p.cubicTo(21.0 * scale, 9.8 * scale, 19.3 * scale, 9.3 * scale,
          18.0 * scale, 8.4 * scale);
      p.cubicTo(17.0 * scale, 7.7 * scale, 16.2 * scale, 6.8 * scale,
          15.6 * scale, 5.8 * scale);
      p.lineTo(15.6 * scale, 15.0 * scale);
      p.cubicTo(15.6 * scale, 18.8 * scale, 12.5 * scale, 22.0 * scale,
          8.5 * scale, 22.0 * scale);
      p.cubicTo(4.8 * scale, 22.0 * scale, 1.8 * scale, 19.0 * scale,
          1.8 * scale, 15.2 * scale);
      p.cubicTo(1.8 * scale, 11.5 * scale, 4.8 * scale, 8.5 * scale,
          8.5 * scale, 8.5 * scale);
      p.cubicTo(9.2 * scale, 8.5 * scale, 9.9 * scale, 8.6 * scale,
          10.5 * scale, 8.8 * scale);
      p.lineTo(10.5 * scale, 12.2 * scale);
      p.cubicTo(9.9 * scale, 11.9 * scale, 9.2 * scale, 11.8 * scale,
          8.5 * scale, 11.8 * scale);
      p.cubicTo(6.6 * scale, 11.8 * scale, 5.1 * scale, 13.3 * scale,
          5.1 * scale, 15.2 * scale);
      p.cubicTo(5.1 * scale, 17.1 * scale, 6.6 * scale, 18.6 * scale,
          8.5 * scale, 18.6 * scale);
      p.cubicTo(10.4 * scale, 18.6 * scale, 12.0 * scale, 17.1 * scale,
          12.0 * scale, 15.2 * scale);
      p.lineTo(12.0 * scale, 2.0 * scale);
      p.close();
      return p;
    }

    final path = createPath();

    // Red shadow/offset (bottom-right)
    canvas.save();
    canvas.translate(1.2 * scale, 1.2 * scale);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFE2C55));
    canvas.restore();

    // Cyan shadow/offset (top-left)
    canvas.save();
    canvas.translate(-1.2 * scale, -1.2 * scale);
    canvas.drawPath(path, Paint()..color = const Color(0xFF25F4EE));
    canvas.restore();

    // White foreground
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
