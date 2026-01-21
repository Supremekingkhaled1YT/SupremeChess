enum ChessPieces {//constants
  whitePawn,
  whiteRook,
  whiteKnight,
  whiteBishop,
  whiteQueen,
  whiteKing,
  blackking;
}
class ChessPiece {// pieces class
  final ChessPieces name;
  final bool isBlack;
  final String imagePath;
  ChessPiece({
    required this.name,    
    required this.isBlack,
    required this.imagePath,
  });
}