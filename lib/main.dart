import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF0B429)),
        textTheme: GoogleFonts.varelaRoundTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFF0B429),
        ),
        textTheme: GoogleFonts.varelaRoundTextTheme(ThemeData.dark().textTheme),
      ),
      home: CalculatorPage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

enum CalculatorMode { basic, scientific }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const String _historyStorageKey = 'calculator_history_v1';

  CalculatorMode _mode = CalculatorMode.basic;

  String _display = '0';
  String _expression = '';
  bool _shouldResetDisplay = false;
  bool _isFunctionInputPending = false;
  final List<String> _history = <String>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_historyStorageKey) ?? <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _history
        ..clear()
        ..addAll(saved);
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyStorageKey, _history);
  }

  void _addHistoryEntry(String entry) {
    _history.insert(0, entry);
    if (_history.length > 100) {
      _history.removeRange(100, _history.length);
    }
    _saveHistory();
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history.clear();
    });
    await _saveHistory();
  }

  final List<String> _buttons = const [
    'C',
    'DEL',
    '%',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '-',
    '1',
    '2',
    '3',
    '+',
    '±',
    '0',
    '.',
    '=',
  ];

  final List<String> _scientificButtons = const [
    'sin',
    'cos',
    'tan',
    'log',
    'ln',
    '√',
    'x²',
    '1/x',
    'xʸ',
    '(',
    ')',
    'abs',
  ];

  void _onButtonPressed(String value) {
    if (value == 'C') {
      _clearAll();
      return;
    }

    if (value == 'DEL') {
      _deleteLast();
      return;
    }

    if (value == '+/-' || value == '±') {
      _toggleSign();
      return;
    }

    if (value == '%') {
      _applyPercent();
      return;
    }

    if (value == '(' || value == ')') {
      _appendParenthesis(value);
      return;
    }

    if (_isOperator(value)) {
      _setOperator(value);
      return;
    }

    if (value == '=') {
      _calculateResult();
      return;
    }

    _appendNumber(value);
  }

  void _onScientificPressed(String value) {
    if (value == 'xʸ') {
      _setOperator('^');
      return;
    }

    if (value == '(' || value == ')') {
      _appendParenthesis(value);
      return;
    }

    _applyScientific(value);
  }

  String _prepareExpressionForAppend() {
    if (_expression.endsWith('=')) {
      return '';
    }
    return _expression;
  }

  bool _isMathOperator(String char) {
    return char == '+' || char == '-' || char == '×' || char == '÷' || char == '^';
  }

  bool _isDigitChar(String char) {
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  bool _canCloseParenthesis(String expr) {
    final open = '('.allMatches(expr).length;
    final close = ')'.allMatches(expr).length;
    return open > close;
  }

  void _appendParenthesis(String token) {
    setState(() {
      var expr = _prepareExpressionForAppend();
      _isFunctionInputPending = false;

      if (token == '(') {
        if (!_shouldResetDisplay && _display != '0') {
          expr += _display;
          expr += '×(';
        } else if (expr.isNotEmpty) {
          final last = expr[expr.length - 1];
          if (_isDigitChar(last) || last == ')' || last == '.') {
            expr += '×(';
          } else {
            expr += '(';
          }
        } else {
          expr = '(';
        }

        _expression = expr;
        _display = '0';
        _shouldResetDisplay = true;
        return;
      }

      if (!_canCloseParenthesis(expr)) {
        return;
      }

      if (!_shouldResetDisplay && _display != '0') {
        expr += _display;
      }

      if (expr.isEmpty) {
        return;
      }

      final last = expr[expr.length - 1];
      if (_isMathOperator(last) || last == '(') {
        return;
      }

      expr += ')';
      _expression = expr;
      _display = '0';
      _shouldResetDisplay = true;
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _expression = '';
      _shouldResetDisplay = false;
      _isFunctionInputPending = false;
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0' || _display == 'Error') {
        return;
      }
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _deleteLast() {
    setState(() {
      if (_shouldResetDisplay) {
        _display = '0';
        _shouldResetDisplay = false;
        return;
      }

      if (_display.length <= 1 || _display == 'Error') {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  void _appendNumber(String value) {
    setState(() {
      if (_expression.endsWith('=')) {
        _expression = '';
        _isFunctionInputPending = false;
      }

      if (_isFunctionInputPending) {
        final openIndex = _expression.lastIndexOf('(');
        final closeIndex = _expression.lastIndexOf(')');
        if (openIndex >= 0 && closeIndex == _expression.length - 1 && openIndex < closeIndex) {
          final currentArg = _expression.substring(openIndex + 1, closeIndex);
          if (value == '.' && currentArg.contains('.')) {
            return;
          }

          final insertValue = value == '.' && currentArg.isEmpty ? '0.' : value;
          _expression = '${_expression.substring(0, closeIndex)}$insertValue)';
          _shouldResetDisplay = true;
          return;
        }

        _isFunctionInputPending = false;
      }

      if (_display == 'Error' || _shouldResetDisplay) {
        _display = value == '.' ? '0.' : value;
        _shouldResetDisplay = false;
        return;
      }

      if (value == '.') {
        if (!_display.contains('.')) {
          _display = '$_display.';
        }
        return;
      }

      if (_display == '0') {
        _display = value;
      } else {
        _display = '$_display$value';
      }
    });
  }

  void _setOperator(String op) {
    setState(() {
      _isFunctionInputPending = false;
      var expr = _prepareExpressionForAppend();

      if (!_shouldResetDisplay) {
        expr += _display;
      } else if (expr.isEmpty) {
        expr = _display;
      }

      if (expr.isEmpty) {
        return;
      }

      final last = expr[expr.length - 1];
      if (_isMathOperator(last)) {
        expr = '${expr.substring(0, expr.length - 1)}$op';
      } else {
        expr += op;
      }

      _expression = expr;
      _shouldResetDisplay = true;
      _display = '0';
    });
  }

  void _calculateResult() {
    var expr = _prepareExpressionForAppend();
    _isFunctionInputPending = false;
    if (!_shouldResetDisplay) {
      expr += _display;
    }

    if (expr.isEmpty) {
      return;
    }

    if (!_canEvaluateExpression(expr)) {
      _showError();
      return;
    }

    final result = _evaluateExpression(expr);
    if (result == null || result.isInfinite || result.isNaN) {
      _showError();
      return;
    }

    setState(() {
      _expression = '$expr=';
      _display = _formatNumber(result);
      _addHistoryEntry('$expr=${_formatNumber(result)}');
      _shouldResetDisplay = true;
    });
  }

  void _applyScientific(String function) {
    setState(() {
      var expr = _prepareExpressionForAppend();

      if (function == 'x²') {
        if (!_shouldResetDisplay) {
          expr += '($_display)^2';
          _display = '0';
          _shouldResetDisplay = true;
        }
        _expression = expr;
        _isFunctionInputPending = false;
        return;
      }

      if (function == '1/x') {
        if (!_shouldResetDisplay) {
          expr += '1/($_display)';
          _display = '0';
          _shouldResetDisplay = true;
        }
        _expression = expr;
        _isFunctionInputPending = false;
        return;
      }

      final mapped = _mapFunctionName(function);
      if (mapped == null) {
        return;
      }

      final hasTypedNumber = !_shouldResetDisplay && _display != '0' && _display != 'Error';

      if (hasTypedNumber) {
        expr += '$mapped($_display)';
        _display = '0';
        _shouldResetDisplay = true;
        _isFunctionInputPending = false;
      } else {
        expr += '$mapped()';
        _isFunctionInputPending = true;
      }

      _expression = expr;
    });
  }

  String? _mapFunctionName(String function) {
    switch (function) {
      case 'sin':
      case 'cos':
      case 'tan':
      case 'log':
      case 'ln':
      case 'abs':
        return function;
      case '√':
        return 'sqrt';
      default:
        return null;
    }
  }

  void _applyPercent() {
    setState(() {
      final value = double.tryParse(_display);
      if (value == null) {
        return;
      }
      _display = _formatNumber(value / 100);
      _shouldResetDisplay = false;
    });
  }

  void _showError() {
    setState(() {
      _applyErrorState();
    });
  }

  void _applyErrorState() {
      _display = 'Error';
      _expression = '';
      _shouldResetDisplay = true;
      _isFunctionInputPending = false;
  }

  bool _canEvaluateExpression(String expr) {
    final open = '('.allMatches(expr).length;
    final close = ')'.allMatches(expr).length;
    if (open != close) {
      return false;
    }

    final trimmed = expr.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final last = trimmed[trimmed.length - 1];
    if (_isMathOperator(last) || last == '(') {
      return false;
    }

    final functionOpen = RegExp(r'(sin|cos|tan|log|ln|abs|sqrt)\(\s*\)');
    return !functionOpen.hasMatch(trimmed);
  }

  int _precedence(String op) {
    switch (op) {
      case '^':
        return 3;
      case '×':
      case '÷':
      case '%':
        return 2;
      case '+':
      case '-':
        return 1;
      default:
        return 0;
    }
  }

  bool _isRightAssociative(String op) => op == '^';

  double? _evaluateExpression(String expr) {
    final tokens = <String>[];
    var i = 0;
    while (i < expr.length) {
      final char = expr[i];

      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      final isUnaryMinus =
          char == '-' &&
          (tokens.isEmpty || _isMathOperator(tokens.last) || tokens.last == '(') &&
          i + 1 < expr.length;

      if (_isDigitChar(char) || char == '.' || isUnaryMinus) {
        final number = StringBuffer()..write(char);
        i++;
        while (i < expr.length && (_isDigitChar(expr[i]) || expr[i] == '.')) {
          number.write(expr[i]);
          i++;
        }
        tokens.add(number.toString());
        continue;
      }

      if (_isMathOperator(char) || char == '(' || char == ')') {
        tokens.add(char);
        i++;
        continue;
      }

      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        final name = StringBuffer()..write(char);
        i++;
        while (i < expr.length && RegExp(r'[A-Za-z]').hasMatch(expr[i])) {
          name.write(expr[i]);
          i++;
        }
        tokens.add(name.toString());
        continue;
      }

      return null;
    }

    final output = <String>[];
    final operators = <String>[];

    for (final token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if (_isFunction(token)) {
        operators.add(token);
      } else if (_isMathOperator(token)) {
        while (operators.isNotEmpty &&
            _isMathOperator(operators.last) &&
            (_precedence(operators.last) > _precedence(token) ||
                (_precedence(operators.last) == _precedence(token) && ! _isRightAssociative(token)))) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      } else if (token == '(') {
        operators.add(token);
      } else if (token == ')') {
        while (operators.isNotEmpty && operators.last != '(') {
          output.add(operators.removeLast());
        }
        if (operators.isEmpty || operators.last != '(') {
          return null;
        }
        operators.removeLast();
        if (operators.isNotEmpty && _isFunction(operators.last)) {
          output.add(operators.removeLast());
        }
      }
    }

    while (operators.isNotEmpty) {
      final op = operators.removeLast();
      if (op == '(' || op == ')') {
        return null;
      }
      output.add(op);
    }

    final stack = <double>[];
    for (final token in output) {
      final number = double.tryParse(token);
      if (number != null) {
        stack.add(number);
        continue;
      }

      if (_isFunction(token)) {
        if (stack.isEmpty) {
          return null;
        }
        final value = stack.removeLast();
        final functionResult = _computeFunction(token, value);
        if (functionResult == null || functionResult.isInfinite || functionResult.isNaN) {
          return null;
        }
        stack.add(functionResult);
        continue;
      }

      if (stack.length < 2) {
        return null;
      }

      final b = stack.removeLast();
      final a = stack.removeLast();
      final result = _compute(a, token, b);
      if (result == null) {
        return null;
      }
      stack.add(result);
    }

    if (stack.length != 1) {
      return null;
    }

    return stack.single;
  }

  bool _isFunction(String token) {
    return token == 'sin' ||
        token == 'cos' ||
        token == 'tan' ||
        token == 'log' ||
        token == 'ln' ||
        token == 'abs' ||
        token == 'sqrt';
  }

  double? _computeFunction(String fn, double value) {
    switch (fn) {
      case 'sin':
        return math.sin(value);
      case 'cos':
        return math.cos(value);
      case 'tan':
        return math.tan(value);
      case 'log':
        if (value <= 0) {
          return null;
        }
        return math.log(value) / math.ln10;
      case 'ln':
        if (value <= 0) {
          return null;
        }
        return math.log(value);
      case 'abs':
        return value.abs();
      case 'sqrt':
        if (value < 0) {
          return null;
        }
        return math.sqrt(value);
      default:
        return null;
    }
  }

  double? _compute(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
      case '*':
        return a * b;
      case '÷':
      case '/':
        if (b == 0) {
          return null;
        }
        return a / b;
      case '^':
        return math.pow(a, b).toDouble();
      default:
        return null;
    }
  }

  bool _isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == '×' ||
        value == '÷' ||
        value == '^';
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatDisplay(String value) {
    if (value == 'Error' || value.isEmpty) {
      return value;
    }

    if (value.contains('e') || value.contains('E')) {
      return value;
    }

    final isNegative = value.startsWith('-');
    final unsigned = isNegative ? value.substring(1) : value;
    final parts = unsigned.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final grouped = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    final formatted = decimalPart.isEmpty ? grouped : '$grouped.$decimalPart';
    return isNegative ? '-$formatted' : formatted;
  }

  void _showHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _history.isEmpty
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              await _clearHistory();
                              if (!mounted) {
                                return;
                              }
                              navigator.pop();
                            },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Belum ada history hitungan.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  SizedBox(
                    height: 260,
                    child: ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (context, _) => Divider(
                        height: 16,
                        color: Theme.of(context).dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        return Text(
                          _history[index],
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = widget.themeMode == ThemeMode.dark;
    final isScientific = _mode == CalculatorMode.scientific;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1B1D) : colors.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: isScientific
              ? _buildScientificLayout(colors, isDark)
              : Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildTopBar(isDark),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_expression.isNotEmpty)
                                    Text(
                                      _expression,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 18,
                                          ),
                                    ),
                                  if (_expression.isNotEmpty) const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _formatDisplay(_display),
                                      key: const ValueKey('display_text'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 58,
                                            color: _display == 'Error' ? colors.error : colors.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      flex: 6,
                      child: _buildButtonMatrix(
                        labels: _buttons,
                        columns: 4,
                        spacing: 10,
                        buttonAspectRatio: 1,
                        buttonBuilder: (label) => _calcButton(label, colors),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CalculatorMode>(
                key: const ValueKey('calc_mode_dropdown'),
                value: _mode,
                onChanged: (mode) {
                  if (mode == null) {
                    return;
                  }
                  setState(() {
                    _mode = mode;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: CalculatorMode.basic,
                    child: Text('Basic'),
                  ),
                  DropdownMenuItem(
                    value: CalculatorMode.scientific,
                    child: Text('Scientific'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: IconButton(
              key: const ValueKey('theme_toggle_btn'),
              onPressed: widget.onToggleTheme,
              iconSize: 28,
              icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('history_btn'),
              onPressed: _showHistorySheet,
              iconSize: 28,
              icon: const Icon(Icons.history),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScientificLayout(ColorScheme colors, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        const blockGap = 8.0;

        final mainButtonsHeight = (totalHeight * 0.50) - blockGap;
        final scientificButtonsTop = totalHeight * 0.30;
        final scientificButtonsHeight = (totalHeight * 0.20) - blockGap;

        final displayTop = totalHeight * 0.20;
        final displayHeight = totalHeight * 0.08;

        final scientificDisplayText = () {
          if (_expression.isNotEmpty && !_expression.endsWith('=')) {
            if (!_shouldResetDisplay && _display != '0' && _display != 'Error') {
              return '$_expression$_display';
            }
            return _expression;
          }
          return _formatDisplay(_display);
        }();

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(isDark),
            ),
            Positioned(
              top: displayTop,
              left: 0,
              right: 0,
              height: displayHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    scientificDisplayText,
                    key: const ValueKey('display_text'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 58,
                          color: _display == 'Error' ? colors.error : colors.onSurface,
                        ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: scientificButtonsTop,
              left: 0,
              right: 0,
              height: scientificButtonsHeight,
              child: _buildButtonMatrix(
                labels: _scientificButtons,
                columns: 4,
                spacing: 8,
                buttonAspectRatio: 1,
                buttonBuilder: (label) => _scientificButton(label, colors),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: mainButtonsHeight,
              child: _buildButtonMatrix(
                labels: _buttons,
                columns: 4,
                spacing: 8,
                buttonAspectRatio: 1,
                buttonBuilder: (label) => _calcButton(label, colors),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonMatrix({
    required List<String> labels,
    required int columns,
    required double spacing,
    required double buttonAspectRatio,
    required Widget Function(String label) buttonBuilder,
  }) {
    final rows = (labels.length / columns).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        if (maxWidth <= 0 || maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final spacingX = columns > 1 ? math.min(spacing, maxWidth / (columns * 6)) : 0.0;
        final spacingY = rows > 1 ? math.min(spacing, maxHeight / (rows * 6)) : 0.0;

        final totalHorizontalSpacing = spacingX * (columns - 1);
        final totalVerticalSpacing = spacingY * (rows - 1);

        final widthBasedCellWidth = (maxWidth - totalHorizontalSpacing) / columns;
        final widthBasedCellHeight = widthBasedCellWidth / buttonAspectRatio;
        final widthBasedMatrixHeight = (widthBasedCellHeight * rows) + totalVerticalSpacing;

        late final double cellWidth;
        late final double cellHeight;
        late final double matrixHeight;

        if (widthBasedMatrixHeight <= maxHeight) {
          cellWidth = widthBasedCellWidth;
          cellHeight = widthBasedCellHeight;
          matrixHeight = widthBasedMatrixHeight;
        } else {
          cellHeight = math.max(0, (maxHeight - totalVerticalSpacing) / rows);
          cellWidth = widthBasedCellWidth;
          matrixHeight = maxHeight;
        }

        if (cellWidth <= 0 || cellHeight <= 0 || matrixHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            height: matrixHeight,
            child: Column(
              children: List.generate(rows, (rowIndex) {
                final start = rowIndex * columns;
                final end = math.min(start + columns, labels.length);
                final rowLabels = labels.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(bottom: rowIndex == rows - 1 ? 0 : spacingY),
                  child: SizedBox(
                    height: cellHeight,
                    child: Row(
                      children: List.generate(columns, (columnIndex) {
                        final hasButton = columnIndex < rowLabels.length;
                        final label = hasButton ? rowLabels[columnIndex] : null;

                        return Padding(
                          padding: EdgeInsets.only(right: columnIndex == columns - 1 ? 0 : spacingX),
                          child: SizedBox(
                            width: cellWidth,
                            height: cellHeight,
                            child: hasButton ? buttonBuilder(label!) : const SizedBox.shrink(),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _scientificButton(String label, ColorScheme colors) {
    return ElevatedButton(
      key: ValueKey('sci_$label'),
      onPressed: () => _onScientificPressed(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurface,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _calcButton(String label, ColorScheme colors) {
    final bool isAccent = label == 'C' || label == '=';
    final bool isOperator = _isOperator(label);
    final bool isUtility = label == 'DEL' || label == '+/-' || label == '±' || label == '(' || label == ')';

    final Color background;
    final Color foreground;

    if (isAccent) {
      background = const Color(0xFFF0B429);
      foreground = const Color(0xFF1F1F1F);
    } else if (isOperator) {
      background = const Color(0xFFF4E1A1);
      foreground = const Color(0xFF3E2E00);
    } else if (isUtility || label == '%') {
      background = colors.surfaceContainerHighest;
      foreground = colors.onSurface;
    } else {
      background = const Color(0xFF3A3A3C);
      foreground = const Color(0xFFF2F2F2);
    }

    return ElevatedButton(
      key: ValueKey('btn_$label'),
      onPressed: () => _onButtonPressed(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 2 ? 19 : 34,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
