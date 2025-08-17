import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(SmartCalculatorApp());
}

class SmartCalculatorApp extends StatelessWidget {
  const SmartCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ماشین حساب هوشمند',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'IranSans',
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.deepPurple),
      home: CalculatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDarkMode = false;
  List<String> _globalHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addToHistory(String calculation) {
    setState(() {
      _globalHistory.insert(0, calculation);
      if (_globalHistory.length > 100) {
        _globalHistory = _globalHistory.sublist(0, 100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: _isDarkMode ? Color(0xFF0D0D0D) : Colors.blue[50],
        appBar: AppBar(
          title: Text(
            'ماشین حساب هوشمند',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          backgroundColor: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(_isDarkMode),
                  color: _isDarkMode ? Colors.yellow : Colors.indigo,
                ),
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                HapticFeedback.lightImpact();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.deepPurple,
            labelColor: _isDarkMode ? Colors.white : Colors.black87,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.calculate), text: 'ماشین حساب'),
              Tab(icon: Icon(Icons.functions), text: 'علمی'),
              Tab(icon: Icon(Icons.fitness_center), text: 'BMI'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'تبدیل واحد'),
              Tab(icon: Icon(Icons.history), text: 'تاریخچه'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            BasicCalculator(
              isDarkMode: _isDarkMode,
              onHistoryAdd: _addToHistory,
            ),
            ScientificCalculator(
              isDarkMode: _isDarkMode,
              onHistoryAdd: _addToHistory,
            ),
            BMICalculator(isDarkMode: _isDarkMode, onHistoryAdd: _addToHistory),
            UnitConverter(isDarkMode: _isDarkMode, onHistoryAdd: _addToHistory),
            HistoryPage(
              isDarkMode: _isDarkMode,
              history: _globalHistory,
              onClearHistory: () {
                setState(() {
                  _globalHistory.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ماشین حساب اصلی
class BasicCalculator extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onHistoryAdd;

  const BasicCalculator({
    super.key,
    required this.isDarkMode,
    required this.onHistoryAdd,
  });

  @override
  _BasicCalculatorState createState() => _BasicCalculatorState();
}

class _BasicCalculatorState extends State<BasicCalculator>
    with TickerProviderStateMixin {
  String _display = '0';
  String _operation = '';
  double _operand1 = 0;
  double _operand2 = 0;
  String _operator = '';
  bool _waitingForOperand = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _displayController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _displayController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(0.1, 0))
        .animate(
          CurvedAnimation(parent: _displayController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    _displayController.forward().then((_) {
      _displayController.reverse();
    });

    setState(() {
      switch (value) {
        case 'AC':
          _clear();
          break;
        case '⌫':
          _backspace();
          break;
        case '±':
          _toggleSign();
          break;
        case '%':
          _percentage();
          break;
        case '÷':
        case '×':
        case '−':
        case '+':
          _setOperator(value);
          break;
        case '=':
          _calculate();
          break;
        case '.':
          _addDecimal();
          break;
        default:
          _addDigit(value);
      }
    });
  }

  void _clear() {
    _display = '0';
    _operation = '';
    _operand1 = 0;
    _operand2 = 0;
    _operator = '';
    _waitingForOperand = false;
  }

  void _backspace() {
    if (_display.length > 1 && _display != '0') {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  void _toggleSign() {
    if (_display != '0') {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    }
  }

  void _percentage() {
    double value = double.tryParse(_display) ?? 0;
    _display = (value / 100).toString();
    _formatDisplay();
  }

  void _addDigit(String digit) {
    if (_waitingForOperand) {
      _display = digit;
      _waitingForOperand = false;
    } else {
      _display = _display == '0' ? digit : _display + digit;
    }
  }

  void _addDecimal() {
    if (_waitingForOperand) {
      _display = '0.';
      _waitingForOperand = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _setOperator(String op) {
    if (!_waitingForOperand && _operator.isNotEmpty) {
      _calculate();
    }
    _operand1 = double.tryParse(_display) ?? 0;
    _operator = op;
    _operation = '$_display $op';
    _waitingForOperand = true;
  }

  void _calculate() {
    if (_operator.isEmpty || _waitingForOperand) return;

    _operand2 = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _operand1 + _operand2;
        break;
      case '−':
        result = _operand1 - _operand2;
        break;
      case '×':
        result = _operand1 * _operand2;
        break;
      case '÷':
        if (_operand2 != 0) {
          result = _operand1 / _operand2;
        } else {
          _display = 'خطا: تقسیم بر صفر';
          _operator = '';
          _operation = '';
          return;
        }
        break;
    }

    String calculation = '$_operand1 $_operator $_operand2 = $result';
    widget.onHistoryAdd(calculation);

    _display = _formatResult(result);
    _operation = '';
    _operator = '';
    _waitingForOperand = true;
  }

  String _formatResult(double result) {
    if (result == result.roundToDouble()) {
      return result.round().toString();
    }
    return result
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _formatDisplay() {
    double value = double.tryParse(_display) ?? 0;
    _display = _formatResult(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.isDarkMode
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        children: [
          // نمایشگر
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_operation.isNotEmpty)
                    AnimatedOpacity(
                      opacity: _operation.isEmpty ? 0.0 : 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        _operation,
                        style: TextStyle(
                          fontSize: 20,
                          color: widget.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _display,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: _display.length > 8 ? 36 : 48,
                          fontWeight: FontWeight.w200,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                          shadows: [
                            Shadow(
                              color: widget.isDarkMode
                                  ? Colors.purple.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // دکمه‌ها
          Expanded(
            flex: 5,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildButtonRow(['AC', '±', '%', '÷']),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '−']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildButtonRow(['⌫', '0', '.', '=']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => _buildButton(button)).toList(),
      ),
    );
  }

  Widget _buildButton(String text) {
    bool isOperator = ['+', '−', '×', '÷', '='].contains(text);
    bool isSpecial = ['AC', '⌫', '±', '%'].contains(text);

    Color backgroundColor;
    Color foregroundColor;

    if (isOperator) {
      backgroundColor = Colors.deepPurple;
      foregroundColor = Colors.white;
    } else if (isSpecial) {
      backgroundColor = widget.isDarkMode
          ? Colors.grey[700]!
          : Colors.grey[300]!;
      foregroundColor = widget.isDarkMode ? Colors.white : Colors.black87;
    } else {
      backgroundColor = widget.isDarkMode ? Colors.grey[850]! : Colors.white;
      foregroundColor = widget.isDarkMode ? Colors.white : Colors.black87;
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(6),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isOperator
                          ? Colors.deepPurple.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _onButtonPressed(text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: foregroundColor,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size(0, 70),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ماشین حساب علمی
class ScientificCalculator extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onHistoryAdd;

  const ScientificCalculator({
    super.key,
    required this.isDarkMode,
    required this.onHistoryAdd,
  });

  @override
  _ScientificCalculatorState createState() => _ScientificCalculatorState();
}

class _ScientificCalculatorState extends State<ScientificCalculator> {
  String _display = '0';
  bool _isRadianMode = false;

  void _onScientificPressed(String function) {
    double value = double.tryParse(_display) ?? 0;
    double result = 0;

    try {
      switch (function) {
        case 'sin':
          result = _isRadianMode
              ? math.sin(value)
              : math.sin(value * math.pi / 180);
          break;
        case 'cos':
          result = _isRadianMode
              ? math.cos(value)
              : math.cos(value * math.pi / 180);
          break;
        case 'tan':
          result = _isRadianMode
              ? math.tan(value)
              : math.tan(value * math.pi / 180);
          break;
        case 'log':
          if (value > 0) {
            result = math.log(value) / math.ln10;
          } else {
            _display = 'خطا';
            return;
          }
          break;
        case 'ln':
          if (value > 0) {
            result = math.log(value);
          } else {
            _display = 'خطا';
            return;
          }
          break;
        case '√':
          if (value >= 0) {
            result = math.sqrt(value);
          } else {
            _display = 'خطا';
            return;
          }
          break;
        case 'x²':
          result = value * value;
          break;
        case 'x³':
          result = value * value * value;
          break;
        case '1/x':
          if (value != 0) {
            result = 1 / value;
          } else {
            _display = 'خطا';
            return;
          }
          break;
        case 'π':
          result = math.pi;
          break;
        case 'e':
          result = math.e;
          break;
      }

      String calculation = '$function($value) = $result';
      widget.onHistoryAdd(calculation);

      setState(() {
        _display = _formatResult(result);
      });
    } catch (e) {
      setState(() {
        _display = 'خطا';
      });
    }
  }

  String _formatResult(double result) {
    if (result == result.roundToDouble()) {
      return result.round().toString();
    }
    return result
        .toStringAsFixed(8)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.isDarkMode
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF2D1B69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        children: [
          // نمایشگر علمی
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isRadianMode ? 'RAD' : 'DEG',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: _isRadianMode,
                      onChanged: (value) {
                        setState(() {
                          _isRadianMode = value;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _display,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // دکمه‌های علمی
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              padding: EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildScientificButton('sin'),
                _buildScientificButton('cos'),
                _buildScientificButton('tan'),
                _buildScientificButton('log'),
                _buildScientificButton('ln'),
                _buildScientificButton('√'),
                _buildScientificButton('x²'),
                _buildScientificButton('x³'),
                _buildScientificButton('1/x'),
                _buildScientificButton('π'),
                _buildScientificButton('e'),
                _buildScientificButton('AC'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificButton(String text) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isDarkMode
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          if (text == 'AC') {
            setState(() {
              _display = '0';
            });
          } else {
            _onScientificPressed(text);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.white : Colors.indigo[800],
          ),
        ),
      ),
    );
  }
}

// محاسبه BMI
class BMICalculator extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onHistoryAdd;

  const BMICalculator({
    super.key,
    required this.isDarkMode,
    required this.onHistoryAdd,
  });

  @override
  _BMICalculatorState createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator>
    with TickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double _bmiResult = 0;
  String _bmiCategory = '';
  Color _categoryColor = Colors.grey;
  late AnimationController _resultAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _resultAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _resultAnimationController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    double height = double.tryParse(_heightController.text) ?? 0;
    double weight = double.tryParse(_weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);

      setState(() {
        _bmiResult = bmi;
        _setBMICategory(bmi);
      });

      String calculation =
          'BMI: وزن=$weight کیلو، قد=$height سانتی = ${bmi.toStringAsFixed(1)} ($_bmiCategory)';
      widget.onHistoryAdd(calculation);

      _resultAnimationController.reset();
      _resultAnimationController.forward();
      HapticFeedback.mediumImpact();
    }
  }

  void _setBMICategory(double bmi) {
    if (bmi < 18.5) {
      _bmiCategory = 'کم‌وزن';
      _categoryColor = Colors.blue;
    } else if (bmi < 25) {
      _bmiCategory = 'وزن نرمال';
      _categoryColor = Colors.green;
    } else if (bmi < 30) {
      _bmiCategory = 'اضافه‌وزن';
      _categoryColor = Colors.orange;
    } else {
      _bmiCategory = 'چاق';
      _categoryColor = Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.isDarkMode
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF1A4D3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[50]!, Colors.teal[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // عنوان
            Container(
              margin: EdgeInsets.only(bottom: 32),
              child: Text(
                '🏃‍♂️ محاسبه شاخص توده بدنی',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // فیلدهای ورودی
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // قد
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'قد (سانتی‌متر)',
                      labelStyle: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                      prefixIcon: Icon(Icons.height, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // وزن
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'وزن (کیلوگرم)',
                      labelStyle: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                      prefixIcon: Icon(
                        Icons.fitness_center,
                        color: Colors.green,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // دکمه محاسبه
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _calculateBMI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        'محاسبه BMI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // نمایش نتیجه BMI
            if (_bmiResult > 0)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _categoryColor.withOpacity(0.1),
                        _categoryColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _categoryColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'نتیجه BMI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        _bmiResult.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _categoryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _bmiCategory,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: _categoryColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildBMIChart(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIChart() {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          _buildBMIRange('کم‌وزن', '< 18.5', Colors.blue, _bmiResult < 18.5),
          _buildBMIRange(
            'نرمال',
            '18.5-24.9',
            Colors.green,
            _bmiResult >= 18.5 && _bmiResult < 25,
          ),
          _buildBMIRange(
            'اضافه‌وزن',
            '25-29.9',
            Colors.orange,
            _bmiResult >= 25 && _bmiResult < 30,
          ),
          _buildBMIRange('چاق', '≥ 30', Colors.red, _bmiResult >= 30),
        ],
      ),
    );
  }

  Widget _buildBMIRange(
    String title,
    String range,
    Color color,
    bool isActive,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              range,
              style: TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// تبدیل واحد
class UnitConverter extends StatefulWidget {
  final bool isDarkMode;
  final Function(String) onHistoryAdd;

  const UnitConverter({
    super.key,
    required this.isDarkMode,
    required this.onHistoryAdd,
  });

  @override
  _UnitConverterState createState() => _UnitConverterState();
}

class _UnitConverterState extends State<UnitConverter> {
  String _selectedCategory = 'length';
  String _fromUnit = 'متر';
  String _toUnit = 'سانتی‌متر';
  final TextEditingController _inputController = TextEditingController();
  String _result = '0';

  final Map<String, Map<String, double>> _conversions = {
    'length': {
      'متر': 1.0,
      'سانتی‌متر': 100.0,
      'میلی‌متر': 1000.0,
      'کیلومتر': 0.001,
      'اینچ': 39.3701,
      'فوت': 3.28084,
    },
    'weight': {
      'کیلوگرم': 1.0,
      'گرم': 1000.0,
      'پوند': 2.20462,
      'اونس': 35.274,
      'تن': 0.001,
    },
    'temperature': {'سلسیوس': 1.0, 'فارنهایت': 1.0, 'کلوین': 1.0},
    'volume': {
      'لیتر': 1.0,
      'میلی‌لیتر': 1000.0,
      'متر مکعب': 0.001,
      'گالن': 0.264172,
      'پینت': 2.11338,
    },
  };

  final Map<String, List<String>> _categoryUnits = {
    'length': ['متر', 'سانتی‌متر', 'میلی‌متر', 'کیلومتر', 'اینچ', 'فوت'],
    'weight': ['کیلوگرم', 'گرم', 'پوند', 'اونس', 'تن'],
    'temperature': ['سلسیوس', 'فارنهایت', 'کلوین'],
    'volume': ['لیتر', 'میلی‌لیتر', 'متر مکعب', 'گالن', 'پینت'],
  };

  void _convert() {
    double inputValue = double.tryParse(_inputController.text) ?? 0;
    double result = 0;

    if (_selectedCategory == 'temperature') {
      result = _convertTemperature(inputValue, _fromUnit, _toUnit);
    } else {
      double fromFactor = _conversions[_selectedCategory]![_fromUnit]!;
      double toFactor = _conversions[_selectedCategory]![_toUnit]!;
      result = inputValue / fromFactor * toFactor;
    }

    setState(() {
      _result = result
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    });

    String conversion = '$inputValue $_fromUnit = $_result $_toUnit';
    widget.onHistoryAdd(conversion);
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    // تبدیل به سلسیوس
    double celsius;
    switch (from) {
      case 'فارنهایت':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'کلوین':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }

    // تبدیل از سلسیوس به واحد مقصد
    switch (to) {
      case 'فارنهایت':
        return celsius * 9 / 5 + 32;
      case 'کلوین':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.isDarkMode
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF4A1B3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // انتخاب دسته‌بندی
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دسته‌بندی:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildCategoryButton('length', 'طول', Icons.straighten),
                      _buildCategoryButton(
                        'weight',
                        'وزن',
                        Icons.fitness_center,
                      ),
                      _buildCategoryButton(
                        'temperature',
                        'دما',
                        Icons.thermostat,
                      ),
                      _buildCategoryButton('volume', 'حجم', Icons.local_drink),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ورودی
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'مقدار ورودی',
                      labelStyle: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                    onChanged: (_) => _convert(),
                  ),
                  SizedBox(height: 20),

                  // انتخاب واحدها
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _fromUnit,
                          decoration: InputDecoration(
                            labelText: 'از واحد',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _categoryUnits[_selectedCategory]!
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _fromUnit = value!;
                            });
                            _convert();
                          },
                          dropdownColor: widget.isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _toUnit,
                          decoration: InputDecoration(
                            labelText: 'به واحد',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _categoryUnits[_selectedCategory]!
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _toUnit = value!;
                            });
                            _convert();
                          },
                          dropdownColor: widget.isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // نتیجه
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.pink.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'نتیجه:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  Text(
                    _toUnit,
                    style: TextStyle(fontSize: 18, color: Colors.purple[300]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category, String label, IconData icon) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _fromUnit = _categoryUnits[category]![0];
          _toUnit = _categoryUnits[category]![1];
          _result = '0';
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.purple : Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (widget.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحه تاریخچه
class HistoryPage extends StatelessWidget {
  final bool isDarkMode;
  final List<String> history;
  final VoidCallback onClearHistory;

  const HistoryPage({
    super.key,
    required this.isDarkMode,
    required this.history,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isDarkMode
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF2D1B1B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        children: [
          // عنوان و دکمه پاک کردن
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📝 تاریخچه محاسبات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (history.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('پاک کردن تاریخچه'),
                          content: Text(
                            'آیا می‌خواهید تمام تاریخچه را پاک کنید؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('انصراف'),
                            ),
                            TextButton(
                              onPressed: () {
                                onClearHistory();
                                Navigator.of(context).pop();
                                HapticFeedback.mediumImpact();
                              },
                              child: Text(
                                'پاک کردن',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.clear_all, color: Colors.white),
                    label: Text(
                      'پاک کردن',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // لیست تاریخچه
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'هیچ محاسبه‌ای در تاریخچه وجود ندارد',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            history[index],
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.copy, color: Colors.grey[600]),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: history[index]),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('کپی شد!'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
