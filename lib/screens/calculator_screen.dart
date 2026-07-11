// lib/screens/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ==================== BUTTON PRESS ====================
  void _onButtonPress(String value) {
    setState(() {
      if (value == 'C') {
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

  // ==================== NUMBER PRESS ====================
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

  // ==================== DECIMAL PRESS ====================
  void _onDecimalPress() {
    if (_isNewCalculation) {
      _output = '0.';
      _isNewCalculation = false;
    } else if (!_output.contains('.')) {
      _output = _output + '.';
    }
    _updateExpression();
  }

  // ==================== OPERATOR PRESS ====================
  void _onOperatorPress(String value) {
    if (_operand.isNotEmpty && !_isNewCalculation) {
      _calculate();
    }
    _num1 = double.tryParse(_output) ?? 0;
    _operand = value;
    _isNewCalculation = true;
    _expression = '$_output $value';
  }

  // ==================== TOGGLE SIGN ====================
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

  // ==================== CALCULATE ====================
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

    _expression = '$_num1 $_operand $_num2 =';

    // Format result
    if (result == result.roundToDouble() && result.toString().length < 12) {
      _output = result.toInt().toString();
    } else {
      _output = result.toStringAsFixed(4);
      // Remove trailing zeros
      if (_output.contains('.')) {
        _output = _output.replaceAll(RegExp(r'0+$'), '');
        if (_output.endsWith('.')) {
          _output = _output.substring(0, _output.length - 1);
        }
      }
    }

    _operand = '';
    _isNewCalculation = true;
    _num1 = result;
  }

  // ==================== BACKSPACE ====================
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

  // ==================== CLEAR ALL ====================
  void _clearAll() {
    _output = '0';
    _expression = '';
    _num1 = 0;
    _num2 = 0;
    _operand = '';
    _isNewCalculation = true;
  }

  // ==================== UPDATE EXPRESSION ====================
  void _updateExpression() {
    if (_operand.isNotEmpty) {
      _expression = '$_num1 $_operand $_output';
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Display Area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF16213E)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Result
                  Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _output,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Buttons Area
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Row 1
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          'C',
                          isSpecial: true,
                          color: Colors.redAccent,
                        ),
                        _buildButton(
                          '⌫',
                          isSpecial: true,
                          color: Colors.orange,
                        ),
                        _buildButton('%', isOperator: true),
                        _buildButton('÷', isOperator: true),
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
                        _buildButton('×', isOperator: true),
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
                        _buildButton('-', isOperator: true),
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
                        _buildButton('+', isOperator: true),
                      ],
                    ),
                  ),
                  // Row 5
                  Expanded(
                    child: Row(
                      children: [
                        _buildButton(
                          '+/-',
                          isSpecial: true,
                          color: Colors.grey,
                        ),
                        _buildButton('0'),
                        _buildButton('.'),
                        _buildButton('=', isEquals: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD BUTTON ====================
  Widget _buildButton(
    String text, {
    bool isOperator = false,
    bool isSpecial = false,
    bool isEquals = false,
    Color? color,
  }) {
    Color bgColor;
    Color textColor = Colors.white;
    double fontSize = 24;

    if (isEquals) {
      bgColor = const Color(0xFF6366F1);
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = const Color(0xFF6366F1).withOpacity(0.2);
      textColor = const Color(0xFF6366F1);
    } else if (isSpecial) {
      bgColor = color?.withOpacity(0.2) ?? Colors.grey.shade800;
      textColor = color ?? Colors.white70;
      fontSize = 20;
    } else {
      bgColor = const Color(0xFF2D2D44);
      textColor = Colors.white;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onButtonPress(text),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isEquals
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
