import 'dart:math';
import 'package:flutter/material.dart';
import 'theme_settings.dart';

class GameScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const GameScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int rows = 10;
  static const int cols = 10;
  static const int mineCount = 15;
  
  late List<List<Cell>> grid;
  bool isGameOver = false;
  bool isWin = false;
  
  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  void initializeGame() {
    grid = List.generate(
      rows,
      (i) => List.generate(
        cols,
        (j) => Cell(),
      ),
    );
    
    int minesPlaced = 0;
    while (minesPlaced < mineCount) {
      int row = Random().nextInt(rows);
      int col = Random().nextInt(cols);
      if (!grid[row][col].hasMine) {
        grid[row][col].hasMine = true;
        minesPlaced++;
      }
    }
    
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (!grid[i][j].hasMine) {
          int count = 0;
          for (int di = -1; di <= 1; di++) {
            for (int dj = -1; dj <= 1; dj++) {
              int ni = i + di;
              int nj = j + dj;
              if (ni >= 0 && ni < rows && nj >= 0 && nj < cols && grid[ni][nj].hasMine) {
                count++;
              }
            }
          }
          grid[i][j].adjacentMines = count;
        }
      }
    }
  }

  void showGameDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: color),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              restartGame();
            },
            child: const Text('Начать заново'),
          ),
        ],
      ),
    );
  }

  void revealCell(int row, int col) {
    if (isGameOver || isWin || grid[row][col].isRevealed || grid[row][col].isFlagged) return;

    setState(() {
      grid[row][col].isRevealed = true;

      if (grid[row][col].hasMine) {
        isGameOver = true;
        revealAllMines();
        showGameDialog(
          'Игра окончена!',
          'Вы наткнулись на мину. Попробуйте еще раз!',
          Colors.red,
        );
        return;
      }

      if (grid[row][col].adjacentMines == 0) {
        for (int di = -1; di <= 1; di++) {
          for (int dj = -1; dj <= 1; dj++) {
            int ni = row + di;
            int nj = col + dj;
            if (ni >= 0 && ni < rows && nj >= 0 && nj < cols && !grid[ni][nj].isRevealed) {
              revealCell(ni, nj);
            }
          }
        }
      }

      checkWin();
    });
  }

  void toggleFlag(int row, int col) {
    if (isGameOver || isWin || grid[row][col].isRevealed) return;

    setState(() {
      grid[row][col].isFlagged = !grid[row][col].isFlagged;
    });
  }

  void revealAllMines() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (grid[i][j].hasMine) {
          grid[i][j].isRevealed = true;
        }
      }
    }
  }

  void checkWin() {
    bool won = true;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (!grid[i][j].hasMine && !grid[i][j].isRevealed) {
          won = false;
          break;
        }
      }
    }
    if (won) {
      isWin = true;
      showGameDialog(
        'Победа!',
        'Поздравляем! Вы успешно нашли все мины!',
        Colors.green,
      );
    }
  }

  void restartGame() {
    setState(() {
      isGameOver = false;
      isWin = false;
      initializeGame();
    });
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => ThemeSettings(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Сапёр'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: restartGame,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 400,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Card(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 1,
                    crossAxisSpacing: 1,
                  ),
                  itemCount: rows * cols,
                  itemBuilder: (context, index) {
                    int row = index ~/ cols;
                    int col = index % cols;
                    return GestureDetector(
                      onTap: () => revealCell(row, col),
                      onSecondaryTap: () => toggleFlag(row, col),
                      child: CellWidget(
                        cell: grid[row][col],
                        isDarkMode: widget.isDarkMode,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Правый клик - поставить флажок',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class Cell {
  bool hasMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int adjacentMines = 0;
}

class CellWidget extends StatelessWidget {
  final Cell cell;
  final bool isDarkMode;

  const CellWidget({
    super.key,
    required this.cell,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: _getCellColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: _getCellContent(),
      ),
    );
  }

  Color _getCellColor() {
    if (!cell.isRevealed) {
      return isDarkMode ? Colors.blue[900]! : Colors.blue[100]!;
    }
    if (cell.hasMine) {
      return Colors.red[300]!;
    }
    return isDarkMode ? Colors.grey[800]! : Colors.white;
  }

  Widget _getCellContent() {
    if (cell.isFlagged) {
      return const Icon(Icons.flag, color: Colors.red);
    }
    if (!cell.isRevealed) {
      return const SizedBox();
    }
    if (cell.hasMine) {
      return const Icon(Icons.close, color: Colors.white);
    }
    if (cell.adjacentMines > 0) {
      return Text(
        '${cell.adjacentMines}',
        style: TextStyle(
          color: _getNumberColor(cell.adjacentMines),
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const SizedBox();
  }

  Color _getNumberColor(int number) {
    if (isDarkMode) {
      switch (number) {
        case 1:
          return Colors.lightBlue;
        case 2:
          return Colors.lightGreen;
        case 3:
          return Colors.red[300]!;
        case 4:
          return Colors.purple[200]!;
        default:
          return Colors.grey[300]!;
      }
    } else {
      switch (number) {
        case 1:
          return Colors.blue;
        case 2:
          return Colors.green;
        case 3:
          return Colors.red;
        case 4:
          return Colors.purple;
        default:
          return Colors.black;
      }
    }
  }
}
