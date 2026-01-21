bool isWhite(int index){
          int x = index ~/ 8 ;
          int y = index % 8;
          bool isWhite = (x + y) % 2 == 0;
          // Alternate colors for the squares
          return isWhite;
}
bool inboard(int row, int col){
  return(row >= 0 && row < 8 && col >= 0 && col < 8);
  }


/*  //Chess pieces initialization
  ChessPiece Pawn = ChessPiece(name:ChessPieces.whitePawn, isWhite: true, imagePath: "pieces/W_pawn.png");//Pawn initialization
  ChessPiece Rook = ChessPiece(name:ChessPieces.whiteRook, isWhite: true, imagePath: "pieces/W_rook.png");//Rook initialization
  ChessPiece Knight = ChessPiece(name:ChessPieces.whiteKnight, isWhite: true, imagePath: "pieces/W_knight.png");//Knight initialization
  ChessPiece Bishop = ChessPiece(name:ChessPieces.whiteBishop, isWhite: true, imagePath: "pieces/W_bishop.png");//Bishop initialization
  ChessPiece Queen = ChessPiece(name:ChessPieces.whiteQueen, isWhite: true, imagePath: "pieces/W_queen.png");//Queen initialization
  ChessPiece King = ChessPiece(name:ChessPieces.whiteKing, isWhite: true, imagePath: "pieces/W_king.png");//King initialization*/