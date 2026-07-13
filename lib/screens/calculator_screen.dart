// lib/screens/calculator_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // ==================== VARIABLES ====================
  String _output = '0';
  String _expression = '';
  double _num1 = 0;
  double _num2 = 0;
  String _operand = '';
  bool _isNewCalculation = true;

  // History
  List<String> _history = [];
  bool _showHistory = false;

  // ==================== BUTTON PRESS ====================
  void _onButtonPress(String value) {
    setState(() {
      if (value == 'AC') {
        _clearAll();
      } else if (value == '⌫') {
        _backspace();
      } else if (value == '=') {
        _calculate();
      } else if (value == '+' ||
          value == '-' ||
          value == '×' ||
          value == '÷' ||
          value == '%') {
        _onOperatorPress(value);
      } else if (value == '.') {
        _onDecimalPress();
      } else if (value == '+/-') {
        _toggleSign();
      } else {
        _onNumberPress(value);
      }
    });
  }

  void _onNumberPress(String value) {
    if (_isNewCalculation) {
      _output = value;
      _isNewCalculation = false;
    } else {
      if (_output == '0') {
        _output = value;
      } else if (_output.length < 12) {
        _output = _output + value;
      }
    }
    _updateExpression();
  }

  void _onDecimalPress() {
    if (_isNewCalculation) {
      _output = '0.';
      _isNewCalculation = false;
    } else if (!_output.contains('.')) {
      _output = _output + '.';
    }
    _updateExpression();
  }

  void _onOperatorPress(String value) {
    if (_operand.isNotEmpty && !_isNewCalculation) {
      _calculate();
    }
    _num1 = double.tryParse(_output) ?? 0;
    _operand = value;
    _isNewCalculation = true;
    _expression = '$_output $value';
  }

  void _toggleSign() {
    if (_output != '0') {
      if (_output.startsWith('-')) {
        _output = _output.substring(1);
      } else {
        _output = '-$_output';
      }
    }
    _updateExpression();
  }

  void _calculate() {
    if (_operand.isEmpty) return;

    _num2 = double.tryParse(_output) ?? 0;
    double result = 0;

    switch (_operand) {
      case '+':
        result = _num1 + _num2;
        break;
      case '-':
        result = _num1 - _num2;
        break;
      case '×':
        result = _num1 * _num2;
        break;
      case '÷':
        if (_num2 == 0) {
          _output = 'Error';
          _expression = 'Cannot divide by zero';
          _operand = '';
          _isNewCalculation = true;
          return;
        }
        result = _num1 / _num2;
        break;
      case '%':
        result = _num1 * (_num2 / 100);
        break;
    }

    String calcExpression = '$_num1 $_operand $_num2 =';
    String formattedResult;

    if (result == result.roundToDouble() && result.toString().length < 12) {
      formattedResult = result.toInt().toString();
    } else {
      formattedResult = result.toStringAsFixed(4);
      if (formattedResult.contains('.')) {
        formattedResult = formattedResult.replaceAll(RegExp(r'0+$'), '');
        if (formattedResult.endsWith('.')) {
          formattedResult = formattedResult.substring(
            0,
            formattedResult.length - 1,
          );
        }
      }
    }

    // Save to history
    _history.insert(0, '$calcExpression $formattedResult');

    _expression = calcExpression;
    _output = formattedResult;
    _operand = '';
    _isNewCalculation = true;
    _num1 = result;
  }

  void _backspace() {
    if (_isNewCalculation) return;
    if (_output.length > 1) {
      _output = _output.substring(0, _output.length - 1);
    } else {
      _output = '0';
      _isNewCalculation = true;
    }
    _updateExpression();
  }

  void _clearAll() {
    _output = '0';
    _expression = '';
    _num1 = 0;
    _num2 = 0;
    _operand = '';
    _isNewCalculation = true;
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _updateExpression() {
    if (_operand.isNotEmpty) {
      _expression = '$_num1 $_operand $_output';
    }
  }

  void _useHistoryItem(int index) {
    final item = _history[index];
    final parts = item.split(' ');
    final result = parts.last;
    setState(() {
      _output = result;
      _expression = '';
      _isNewCalculation = true;
      _showHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 310,
            height: 580,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.3),
                  Colors.blue.shade50.withOpacity(0.3),
                  Colors.purple.shade50.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(33),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    // Notch
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Display Area
                    Expanded(
                      flex: _showHistory ? 2 : 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Top Row: History & Clear
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showHistory = !_showHistory;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _showHistory
                                          ? const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.15)
                                          : Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.history,
                                          size: 14,
                                          color: _showHistory
                                              ? const Color(0xFF6366F1)
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${_history.length}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _showHistory
                                                ? const Color(0xFF6366F1)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_history.isNotEmpty)
                                  GestureDetector(
                                    onTap: _clearHistory,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 12,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'Clear',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),

                            // Expression
                            if (!_showHistory) ...[
                              Text(
                                _expression,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 6),
                            ],

                            // Result or History
                            if (_showHistory)
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(top: 6),
                                  itemCount: _history.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _useHistoryItem(index),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _history[index],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Text(
                                _output,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w300,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons Area
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            // Row 1
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton(
                                    'AC',
                                    bgColor: Colors.red.withOpacity(0.12),
                                    textColor: Colors.red,
                                    fontSize: 16,
                                  ),
                                  _buildButton(
                                    '+/-',
                                    bgColor: Colors.white.withOpacity(0.4),
                                    textColor: Colors.grey.shade700,
                                    fontSize: 16,
                                  ),
                                  _buildButton(
                                    '%',
                                    bgColor: Colors.white.withOpacity(0.4),
                                    textColor: Colors.grey.shade700,
                                    fontSize: 16,
                                  ),
                                  _buildButton(
                                    '÷',
                                    bgColor: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                            ),
                            // Row 2
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('7'),
                                  _buildButton('8'),
                                  _buildButton('9'),
                                  _buildButton(
                                    '×',
                                    bgColor: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                            ),
                            // Row 3
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('4'),
                                  _buildButton('5'),
                                  _buildButton('6'),
                                  _buildButton(
                                    '-',
                                    bgColor: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                            ),
                            // Row 4
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton('1'),
                                  _buildButton('2'),
                                  _buildButton('3'),
                                  _buildButton(
                                    '+',
                                    bgColor: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.12),
                                    textColor: const Color(0xFF6366F1),
                                  ),
                                ],
                              ),
                            ),
                            // Row 5
                            Expanded(
                              child: Row(
                                children: [
                                  _buildButton(
                                    '⌫',
                                    bgColor: Colors.white.withOpacity(0.4),
                                    textColor: Colors.grey.shade700,
                                    fontSize: 17,
                                  ),
                                  _buildButton('0'),
                                  _buildButton('.'),
                                  _buildButton(
                                    '=',
                                    bgColor: const Color(0xFF6366F1),
                                    textColor: Colors.white,
                                    isEquals: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Home Indicator
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: 100,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== BUILD BUTTON ====================
  Widget _buildButton(
    String text, {
    Color? bgColor,
    Color? textColor,
    bool isEquals = false,
    double? fontSize,
  }) {
    Color buttonBg = bgColor ?? Colors.white.withOpacity(0.5);
    Color buttonText = textColor ?? const Color(0xFF1E293B);
    double buttonFontSize = fontSize ?? (text.length > 1 ? 14 : 22);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onButtonPress(text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: isEquals
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: isEquals ? FontWeight.w600 : FontWeight.w500,
                color: buttonText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
