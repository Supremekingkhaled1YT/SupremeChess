import 'package:chess_game/components/pieces.dart';
import 'package:flutter/material.dart';

class Square extends StatelessWidget {
  final bool isBlack;
  final ChessPiece? piece;
  final bool isSelected;
  final void Function() onTap;
  final bool isValidMove;
  final bool isSpecialSquare;

  const Square({
    super.key,
    required this.isBlack,
    required this.piece,
    required this.isSelected,
    required this.onTap,
    required this.isValidMove,
    this.isSpecialSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? squareColor;

    if (isSelected) {
      squareColor = Colors.green;
    } else if (isValidMove && piece != null) {
      squareColor = Colors.red.withOpacity(0.7); // Capture move
    } else if (isValidMove) {
      squareColor = Colors.green.withOpacity(0.5); // Valid move
    } else if (isSpecialSquare) {
      squareColor = Colors.amber.withOpacity(0.5); // Special move (en passant, castling)
    } else {
      squareColor = isBlack 
          ? const Color.fromARGB(255, 120, 88, 233)
          : const Color.fromARGB(255, 224, 224, 224);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        child: piece != null
            ? Image.asset(
                piece!.imagePath,
                color: piece!.isBlack
                    ? const Color.fromARGB(255, 0, 0, 0)
                    : const Color.fromARGB(255, 255, 255, 255),
              )
            : isValidMove
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}