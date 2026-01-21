import 'package:chess_game/components/pieces.dart';
import 'package:flutter/material.dart';
import 'package:chess_game/reuseFunctions/funcs.dart';
import 'package:chess_game/components/square.dart';

class Mainboard extends StatefulWidget {
  const Mainboard({super.key});

  @override
  State<Mainboard> createState() => _MainboardState();
}

class Deadpieces extends StatelessWidget {
  final String imagepath;
  final bool isBlack;
  
  const Deadpieces({super.key, required this.imagepath, required this.isBlack});
  
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagepath,
      color: isBlack
          ? const Color.fromARGB(255, 255, 255, 255)
          : const Color.fromARGB(255, 0, 0, 0), // Color comparison
    );
  }
}

class _MainboardState extends State<Mainboard> {
  late List<List<ChessPiece?>> board; // Board initialization
  ChessPiece? selectedPiece; // Selected piece initialization
  int selectedRow = -1;
  int selectedCol = -1;
  List<List<int>> validmoves = []; // Storing valid moves
  bool isblackturn = false; // Track whose turn it is
  List<ChessPiece> whitePieces = []; // Captured white pieces
  List<ChessPiece> blackPieces = []; // Captured black pieces

  // Game state variables
  List<int> BKP = [0, 4]; // Black king position - corrected initial position
  List<int> WKP = [7, 4]; // White king position - corrected initial position
  bool ischeck = false;
  bool isCheckmate = false;

  // Castling state variables
  bool whiteKingMoved = false;
  bool blackKingMoved = false;
  bool whiteRookAMoved = false; // a1 rook (queenside)
  bool whiteRookHMoved = false; // h1 rook (kingside)
  bool blackRookAMoved = false; // a8 rook (queenside)
  bool blackRookHMoved = false; // h8 rook (kingside)

  // En passant state variables
  List<int>? enPassantTarget; // Coordinates of square where en passant capture is possible
  
  // Promotion dialog flag
  bool showingPromotionDialog = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void pieceSelected(int row, int col) {
    // Don't allow selection during promotion dialog
    if (showingPromotionDialog) return;
    
    setState(() {
      // Check for piece selection: either select a piece or move it
      if (selectedPiece == null) {
        if (board[row][col] == null) return; // No piece is selected
        if (board[row][col]?.isBlack == isblackturn) {
          // Only allow selection if the piece belongs to the current player
          selectedPiece = board[row][col]; // Select the piece
          selectedRow = row;
          selectedCol = col;
          validmoves = calculaterealmoves(row, col, selectedPiece); // Calculate valid moves - fixed parameter
        }
      } else {
        // Check if the move is valid
        if (validmoves.any((position) => position[0] == row && position[1] == col)) {
          movepiece(row, col); // Move the piece
        } else {
          // If clicking on a different piece of the same color, select that instead
          if (board[row][col] != null && board[row][col]?.isBlack == isblackturn) {
            selectedPiece = board[row][col];
            selectedRow = row;
            selectedCol = col;
            validmoves = calculaterealmoves(row, col, selectedPiece);
            return;
          }
          // Otherwise, deselect the current piece
          selectedPiece = null;
          selectedRow = -1;
          selectedCol = -1;
          validmoves = [];
        }
      }
    });
  }

  bool isInCheckmate(bool isBlackKing) {
    // First check if the king is in check
    if (!kingincheck(isBlackKing)) {
      return false;
    }
    
    // Get the king's position
    List<int> kingPosition = isBlackKing ? BKP : WKP;
    
    // Check if the king has any legal moves
    ChessPiece? king = board[kingPosition[0]][kingPosition[1]];
    if (king == null) return false; // Safety check
    
    List<List<int>> kingMoves = calculaterealmoves(kingPosition[0], kingPosition[1], king);
    if (kingMoves.isNotEmpty) {
      return false; // King can move out of check
    }
    
    // Check if any other piece can block the check or capture the attacking piece
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Skip empty squares and opponent's pieces
        if (board[i][j] == null || board[i][j]!.isBlack != isBlackKing) {
          continue;
        }
        
        // Skip the king as we already checked its moves
        if (i == kingPosition[0] && j == kingPosition[1]) {
          continue;
        }
        
        // Check if this piece has any legal moves
        List<List<int>> pieceMoves = calculaterealmoves(i, j, board[i][j]);
        if (pieceMoves.isNotEmpty) {
          return false; // This piece can make a move to prevent checkmate
        }
      }
    }
    
    return true; // No legal moves available - checkmate
  }

  void showPromotionDialog(int row, int col) {
    showingPromotionDialog = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionOption(context, row, col, ChessPieces.whiteQueen, "queen"),
              _buildPromotionOption(context, row, col, ChessPieces.whiteRook, "rock"),
              _buildPromotionOption(context, row, col, ChessPieces.whiteBishop, "bishop"),
              _buildPromotionOption(context, row, col, ChessPieces.whiteKnight, "knight"),
            ],
          ),
        );
      },
    ).then((_) {
      showingPromotionDialog = false;
    });
  }

  Widget _buildPromotionOption(BuildContext context, int row, int col, ChessPieces piece, String label) {
    bool isBlack = isblackturn;
    String imagePath = isBlack ? "pieces/W_${label.toLowerCase()}.png" : "pieces/W_${label.toLowerCase()}.png";
    
    return InkWell(
      onTap: () {
        // Create the promoted piece
        ChessPiece promotedPiece = ChessPiece(
          name: piece,
          isBlack: isBlack,
          imagePath: imagePath,
        );
        
        // Place the promoted piece on the board
        board[row][col] = promotedPiece;
        
        // Complete the move
        finalizeMoveAndSwitchTurn();
        
        Navigator.of(context).pop();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            color: isBlack 
              ? const Color.fromARGB(255, 255, 255, 255)
              : const Color.fromARGB(255, 0, 0, 0),
            width: 50,
            height: 50,
          ),
          Text(label),
        ],
      ),
    );
  }

  void movepiece(int row, int col) {
    ChessPiece? movingPiece = selectedPiece;
    if (movingPiece == null) return;
    
    bool isPawnPromotion = false;
    bool isEnPassantCapture = false;
    bool isCastling = false;
    int castlingDirection = 0; // 1 for kingside, -1 for queenside
    
    // Check if this is a pawn promotion
    if (movingPiece.name == ChessPieces.whitePawn) {
      if ((movingPiece.isBlack && row == 7) || (!movingPiece.isBlack && row == 0)) {
        isPawnPromotion = true;
      }
    }
    
    // Check if this is an en passant capture
    if (movingPiece.name == ChessPieces.whitePawn && 
        enPassantTarget != null && 
        row == enPassantTarget![0] && 
        col == enPassantTarget![1]) {
      isEnPassantCapture = true;
    }
    
    // Check if this is castling
    if ((movingPiece.name == ChessPieces.whiteKing || movingPiece.name == ChessPieces.blackking) &&
        (col == selectedCol + 2 || col == selectedCol - 2)) {
      isCastling = true;
      castlingDirection = col > selectedCol ? 1 : -1; // 1 for kingside, -1 for queenside
    }
    
    // Capture handling
    if (board[row][col] != null && !isCastling) {
      // Normal capture
      if (board[row][col]!.isBlack) {
        blackPieces.add(board[row][col]!);
      } else {
        whitePieces.add(board[row][col]!);
      }
    } else if (isEnPassantCapture) {
      // En passant capture
      int capturedPawnRow = movingPiece.isBlack ? row - 1 : row + 1;
      if (board[capturedPawnRow][col] != null) {
        if (board[capturedPawnRow][col]!.isBlack) {
          blackPieces.add(board[capturedPawnRow][col]!);
        } else {
          whitePieces.add(board[capturedPawnRow][col]!);
        }
        board[capturedPawnRow][col] = null; // Remove the captured pawn
      }
    }
    
    // Update king position if the king is moved
    if (movingPiece.name == ChessPieces.whiteKing) {
      WKP = [row, col];
      whiteKingMoved = true;
    } else if (movingPiece.name == ChessPieces.blackking) { 
      BKP = [row, col];
      blackKingMoved = true;
    }
    
    // Update rook movement state for castling
    if (movingPiece.name == ChessPieces.whiteRook) {
      if (selectedRow == 7 && selectedCol == 0) whiteRookAMoved = true;
      if (selectedRow == 7 && selectedCol == 7) whiteRookHMoved = true;
    } else if (movingPiece.name == ChessPieces.whiteRook && movingPiece.isBlack) {
      if (selectedRow == 0 && selectedCol == 0) blackRookAMoved = true;
      if (selectedRow == 0 && selectedCol == 7) blackRookHMoved = true;
    }
    
    // Clear en passant target from previous move
    enPassantTarget = null;
    
    // Set new en passant target if applicable
    if (movingPiece.name == ChessPieces.whitePawn && 
        (selectedRow - row).abs() == 2) {
      int enPassantRow = movingPiece.isBlack ? selectedRow + 1 : selectedRow - 1;
      enPassantTarget = [enPassantRow, selectedCol];
    }
    
    // Move the piece on the board
    board[row][col] = movingPiece;
    board[selectedRow][selectedCol] = null;
    
    // Handle castling rook movement
    if (isCastling) {
      int rookOrigCol = castlingDirection == 1 ? 7 : 0;
      int rookDestCol = castlingDirection == 1 ? col - 1 : col + 1;
      int rookRow = row; // Same row as king
      
      // Move the rook
      board[rookRow][rookDestCol] = board[rookRow][rookOrigCol];
      board[rookRow][rookOrigCol] = null;
    }
    
    // Handle pawn promotion
    if (isPawnPromotion) {
      showPromotionDialog(row, col);
      return; // Exit early - move will be finalized after promotion choice
    }
    
    finalizeMoveAndSwitchTurn();
  }
  
  void finalizeMoveAndSwitchTurn() {
    // Check if opponent's king is in check after the move
    bool opponentIsBlack = !isblackturn;
    ischeck = kingincheck(opponentIsBlack);
    
    // Check for checkmate if the opponent is in check
    isCheckmate = ischeck && isInCheckmate(opponentIsBlack);

    // Switch turns after a successful move
    isblackturn = !isblackturn; 

    setState(() {
      selectedRow = -1; // Reset selected row
      selectedCol = -1; // Reset selected column
      selectedPiece = null; // Deselect the piece
      validmoves = []; // Clear valid moves
    });
  }

  List<List<int>> calculaterawmoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidatemoves = [];
    if (piece == null) return candidatemoves; // No piece is selected

    int direction = piece.isBlack ? 1 : -1; // Forward movement direction

    switch (piece.name) {
      case ChessPieces.whitePawn:
        // Add logic for pawn movements
        if (inboard(row + direction, col) && board[row + direction][col] == null) {
          candidatemoves.add([row + direction, col]); // Forward move
        }
        if ((row == 1 && piece.isBlack) || (row == 6 && !piece.isBlack)) {
          if (inboard(row + 2 * direction, col) && 
              board[row + 2 * direction][col] == null && 
              board[row + direction][col] == null) {
            candidatemoves.add([row + 2 * direction, col]); // Double step move
          }
        }
        // Diagonal captures
        if (inboard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null && 
            board[row + direction][col - 1]!.isBlack != piece.isBlack) {
          candidatemoves.add([row + direction, col - 1]);
        }
        if (inboard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null && 
            board[row + direction][col + 1]!.isBlack != piece.isBlack) {
          candidatemoves.add([row + direction, col + 1]);
        }
        
        // En passant captures
        if (enPassantTarget != null && inboard(enPassantTarget![0], enPassantTarget![1])) {
          if (row + direction == enPassantTarget![0] && (col - 1 == enPassantTarget![1] || col + 1 == enPassantTarget![1])) {
            candidatemoves.add([enPassantTarget![0], enPassantTarget![1]]);
          }
        }
        break;

      case ChessPieces.whiteRook:
        // Rook movement calculations
        for (int d = 1; d < 8; d++) {
          if (inboard(row + d, col) && board[row + d][col] == null) {
            candidatemoves.add([row + d, col]);
          } else if (inboard(row + d, col) && board[row + d][col]?.isBlack != piece.isBlack) {
            candidatemoves.add([row + d, col]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row - d, col) && board[row - d][col] == null) {
            candidatemoves.add([row - d, col]);
          } else if (inboard(row - d, col) && board[row - d][col]?.isBlack != piece.isBlack) {
            candidatemoves.add([row - d, col]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row, col + d) && board[row][col + d] == null) {
            candidatemoves.add([row, col + d]);
          } else if (inboard(row, col + d) && board[row][col + d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row, col + d]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row, col - d) && board[row][col - d] == null) {
            candidatemoves.add([row, col - d]);
          } else if (inboard(row, col - d) && board[row][col - d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row, col - d]);
            break;
          } else {
            break;
          }
        }
        break;

      case ChessPieces.whiteKnight:
        // Knight movements
        const knightMoves = [
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2],
        ];
        for (var move in knightMoves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (inboard(newRow, newCol) && 
              (board[newRow][newCol] == null || 
              board[newRow][newCol]!.isBlack != piece.isBlack)) {
            candidatemoves.add([newRow, newCol]);
          }
        }
        break;

      case ChessPieces.whiteBishop:
        // Bishop movements
        for (int d = 1; d < 8; d++) {
          if (inboard(row + d, col + d) && board[row + d][col + d] == null) {
            candidatemoves.add([row + d, col + d]);
          } else if (inboard(row + d, col + d) && board[row + d][col + d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row + d, col + d]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row + d, col - d) && board[row + d][col - d] == null) {
            candidatemoves.add([row + d, col - d]);
          } else if (inboard(row + d, col - d) && board[row + d][col - d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row + d, col - d]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row - d, col + d) && board[row - d][col + d] == null) {
            candidatemoves.add([row - d, col + d]);
          } else if (inboard(row - d, col + d) && board[row - d][col + d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row - d, col + d]);
            break;
          } else {
            break;
          }
        }
        for (int d = 1; d < 8; d++) {
          if (inboard(row - d, col - d) && board[row - d][col - d] == null) {
            candidatemoves.add([row - d, col - d]);
          } else if (inboard(row - d, col - d) && board[row - d][col - d]?.isBlack != piece.isBlack) {
            candidatemoves.add([row - d, col - d]);
            break;
          } else {
            break;
          }
        }
        break;

      case ChessPieces.whiteQueen:
        // Queen movements
        var directions = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [-1, -1],
          [1, -1],
          [-1, 1],
        ];
        for (var direction in directions) {
          for (int d = 1; d < 8; d++) {
            int newRow = row + d * direction[0];
            int newCol = col + d * direction[1];
            if (inboard(newRow, newCol) && board[newRow][newCol] == null) {
              candidatemoves.add([newRow, newCol]);
            } else if (inboard(newRow, newCol) && board[newRow][newCol]!.isBlack != piece.isBlack) {
              candidatemoves.add([newRow, newCol]);
              break;
            } else {
              break;
            }
          }
        }
        break;

      case ChessPieces.whiteKing:
      case ChessPieces.blackking:
        // King movements
        const kingMoves = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
          [1, 1],
          [-1, -1],
          [1, -1],
          [-1, 1],
        ];
        for (var move in kingMoves) {
          int newRow = row + move[0];
          int newCol = col + move[1];
          if (inboard(newRow, newCol)) {
            // Check if the destination square is either empty or occupied by an opponent's piece
            if (board[newRow][newCol] == null || 
                board[newRow][newCol]!.isBlack != piece.isBlack) {
              candidatemoves.add([newRow, newCol]);
            }
          }
        }
        
        // Add castling moves
        if (!piece.isBlack && !whiteKingMoved && row == 7 && col == 4) {
          // White kingside castling
          if (!whiteRookHMoved && 
              board[7][5] == null && 
              board[7][6] == null && 
              !isSquareUnderAttack(7, 4, true) &&
              !isSquareUnderAttack(7, 5, true) &&
              !isSquareUnderAttack(7, 6, true)) {
            candidatemoves.add([7, 6]); // Kingside castling
          }
          // White queenside castling
          if (!whiteRookAMoved && 
              board[7][1] == null && 
              board[7][2] == null && 
              board[7][3] == null &&
              !isSquareUnderAttack(7, 4, true) &&
              !isSquareUnderAttack(7, 3, true) &&
              !isSquareUnderAttack(7, 2, true)) {
            candidatemoves.add([7, 2]); // Queenside castling
          }
        } else if (piece.isBlack && !blackKingMoved && row == 0 && col == 4) {
          // Black kingside castling
          if (!blackRookHMoved && 
              board[0][5] == null && 
              board[0][6] == null && 
              !isSquareUnderAttack(0, 4, false) &&
              !isSquareUnderAttack(0, 5, false) &&
              !isSquareUnderAttack(0, 6, false)) {
            candidatemoves.add([0, 6]); // Kingside castling
          }
          // Black queenside castling
          if (!blackRookAMoved && 
              board[0][1] == null && 
              board[0][2] == null && 
              board[0][3] == null &&
              !isSquareUnderAttack(0, 4, false) &&
              !isSquareUnderAttack(0, 3, false) &&
              !isSquareUnderAttack(0, 2, false)) {
            candidatemoves.add([0, 2]); // Queenside castling
          }
        }
        break;
    }
    return candidatemoves;
  }

  List<List<int>> calculaterealmoves(int row, int col, ChessPiece? piece) {
    if (piece == null) return [];
    
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculaterawmoves(row, col, piece);
    
    // Check each move to ensure it doesn't leave the king in check
    for (var move in candidateMoves) {
      if (simulation(piece, row, col, move[0], move[1])) {
        realValidMoves.add(move);
      }
    }
    
    return realValidMoves;
  }
  
  bool simulation(ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    // Store the piece at the destination for reverting later
    ChessPiece? tempPiece = board[endRow][endCol];
    
    // Temporarily store king positions
    List<int> originalWKP = [...WKP];
    List<int> originalBKP = [...BKP];
    
    // For en passant simulation
    ChessPiece? capturedPawn;
    int capturedPawnRow = -1;
    int capturedPawnCol = -1;
    
    // Check if this is an en passant move
    bool isEnPassant = false;
    if (piece.name == ChessPieces.whitePawn && 
        enPassantTarget != null &&
        endRow == enPassantTarget![0] && 
        endCol == enPassantTarget![1]) {
      isEnPassant = true;
      capturedPawnRow = piece.isBlack ? endRow - 1 : endRow + 1;
      capturedPawnCol = endCol;
      capturedPawn = board[capturedPawnRow][capturedPawnCol];
      // Remove the pawn temporarily
      board[capturedPawnRow][capturedPawnCol] = null;
    }
    
    // Check if this is a castling move
    bool isCastling = false;
    int castlingDirection = 0;
    ChessPiece? tempRook;
    int rookOrigRow = -1, rookOrigCol = -1, rookDestRow = -1, rookDestCol = -1;
    
    if ((piece.name == ChessPieces.whiteKing || piece.name == ChessPieces.blackking) &&
        (endCol == startCol + 2 || endCol == startCol - 2)) {
      isCastling = true;
      castlingDirection = endCol > startCol ? 1 : -1;
      rookOrigRow = startRow;
      rookOrigCol = castlingDirection == 1 ? 7 : 0;
      rookDestRow = startRow;
      rookDestCol = castlingDirection == 1 ? endCol - 1 : endCol + 1;
      
      // Save the rook
      tempRook = board[rookOrigRow][rookOrigCol];
      
      // Move the rook
      board[rookDestRow][rookDestCol] = tempRook;
      board[rookOrigRow][rookOrigCol] = null;
    }
    
    // If moving king, update king position temporarily
    if (piece.name == ChessPieces.whiteKing) {
      WKP = [endRow, endCol];
    } else if (piece.name == ChessPieces.blackking) {
      BKP = [endRow, endCol];
    }
    
    // Make the move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;
    
    // Check if OUR king is in check after the move
    bool isKingInCheck = kingincheck(piece.isBlack);
    
    // Revert the move
    board[startRow][startCol] = piece;
    board[endRow][endCol] = tempPiece;
    
    // Revert en passant capture
    if (isEnPassant && capturedPawn != null) {
      board[capturedPawnRow][capturedPawnCol] = capturedPawn;
    }
    
    // Revert castling
    if (isCastling && tempRook != null) {
      board[rookOrigRow][rookOrigCol] = tempRook;
      board[rookDestRow][rookDestCol] = null;
    }
    
    // Restore original king positions
    WKP = originalWKP;
    BKP = originalBKP;
    
    // Return true if the move is valid (king is NOT in check)
    return !isKingInCheck;
  }

  // Check if a square is under attack by opponent pieces
  bool isSquareUnderAttack(int row, int col, bool byBlackPieces) {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Skip empty squares and pieces of the wrong color
        if (board[i][j] == null || board[i][j]!.isBlack != byBlackPieces) {
          continue;
        }
        
        // Get raw moves for this piece
        List<List<int>> pieceMoves = calculaterawmoves(i, j, board[i][j]);
        
        // Check if any move targets the specified square
        if (pieceMoves.any((position) => 
            position[0] == row && position[1] == col)) {
          return true; // Square is under attack
        }
      }
    }
    
    return false; // Square is not under attack
  }
void _initializeBoard() {
    board = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    ); // Board generation

    // Initialize Pawns
    for (int i = 0; i < 8; i++) {
      board[1][i] = ChessPiece(
        name: ChessPieces.whitePawn,
        isBlack: true,
        imagePath: "pieces/W_pawn.png",
      ); // Black Pawns
      board[6][i] = ChessPiece(
        name: ChessPieces.whitePawn,
        isBlack: false,
        imagePath: "pieces/W_pawn.png",
      ); // White Pawns
    }

    // Initialize Rooks
    board[0][0] = ChessPiece(
      name: ChessPieces.whiteRook,
      isBlack: true,
      imagePath: "pieces/W_rock.png",
    ); // Black Rook
    board[0][7] = ChessPiece(
      name: ChessPieces.whiteRook,
      isBlack: true,
      imagePath: "pieces/W_rock.png",
    ); // Black Rook
    board[7][0] = ChessPiece(
      name: ChessPieces.whiteRook,
      isBlack: false,
      imagePath: "pieces/W_rock.png",
    ); // White Rook
    board[7][7] = ChessPiece(
      name: ChessPieces.whiteRook,
      isBlack: false,
      imagePath: "pieces/W_rock.png",
    ); // White Rook

    // Initialize Knights
    board[0][1] = ChessPiece(
      name: ChessPieces.whiteKnight,
      isBlack: true,
      imagePath: "pieces/W_knight.png",
    ); // Black Knight
    board[0][6] = ChessPiece(
      name: ChessPieces.whiteKnight,
      isBlack: true,
      imagePath: "pieces/W_knight.png",
    ); // Black Knight
    board[7][1] = ChessPiece(
      name: ChessPieces.whiteKnight,
      isBlack: false,
      imagePath: "pieces/W_knight.png",
    ); // White Knight
    board[7][6] = ChessPiece(
      name: ChessPieces.whiteKnight,
      isBlack: false,
      imagePath: "pieces/W_knight.png",
    ); // White Knight

    // Initialize Bishops
    board[0][2] = ChessPiece(
      name: ChessPieces.whiteBishop,
      isBlack: true,
      imagePath: "pieces/W_bishop.png",
    ); // Black Bishop
    board[0][5] = ChessPiece(
      name: ChessPieces.whiteBishop,
      isBlack: true,
      imagePath: "pieces/W_bishop.png",
    ); // Black Bishop
    board[7][2] = ChessPiece(
      name: ChessPieces.whiteBishop,
      isBlack: false,
      imagePath: "pieces/W_bishop.png",
    ); // White Bishop
    board[7][5] = ChessPiece(
      name: ChessPieces.whiteBishop,
      isBlack: false,
      imagePath: "pieces/W_bishop.png",
    ); // White Bishop

    // Initialize Queens & Kings
    board[0][3] = ChessPiece(
      name: ChessPieces.whiteQueen,
      isBlack: true,
      imagePath: "pieces/W_queen.png",
    ); // Black Queen
    board[0][4] = ChessPiece(
      name: ChessPieces.blackking,
      isBlack: true,
      imagePath: "pieces/W_king.png",
    ); // Black King - Fixed name
    board[7][3] = ChessPiece(
      name: ChessPieces.whiteQueen,
      isBlack: false,
      imagePath: "pieces/W_queen.png",
    ); // White Queen
    board[7][4] = ChessPiece(
      name: ChessPieces.whiteKing,
      isBlack: false,
      imagePath: "pieces/W_king.png",
    ); // White King - Fixed name
  }

  bool isBlack(int index) {
    // Determine if the square is white or black
    return (index ~/ 8 % 2 == 0) ? index % 2 == 0 : index % 2 != 0;
  }

  bool kingincheck(bool isBlackKing) {
    List<int> kingPosition = isBlackKing ? BKP : WKP;
    
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Skip empty squares and pieces of the same color as the king
        if (board[i][j] == null || board[i][j]!.isBlack == isBlackKing) {
          continue;
        }
        
        // Get raw moves without simulation to avoid infinite recursion
        List<List<int>> piecesValidMoves = calculaterawmoves(i, j, board[i][j]);
        
        // Check if any valid move targets the king's position
        if (piecesValidMoves.any((position) => 
            position[0] == kingPosition[0] && position[1] == kingPosition[1])) {
          return true; // King is in check
        }
      }
    }
    
    return false; // King is not in check
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 88, 33, 240),
      body: Column(
        children: [
          // Declaring the pieces for white
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: whitePieces.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => Deadpieces(
                imagepath: whitePieces[index].imagePath,
                isBlack: true,
              ),
            ),
          ),
          // Game state indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCheckmate)
                const Text(
                  "Checkmate!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              else if (ischeck)
                const Text(
                  "Check",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              if (enPassantTarget != null)
                const SizedBox(width: 10),
                const Text(
                  "",
                  style: TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          // Chessboard
          Expanded(
            flex: 5,
            child: GridView.builder(
              itemCount: 8 * 8, // Grid
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                // Piece builder
                int row = index ~/ 8; // Determine row
                int col = index % 8; // Determine column
                bool isValidMove = validmoves.any(
                  (position) => position[0] == row && position[1] == col,
                ); // Check if the move is valid

                // Highlight squares for special moves
                bool isSpecialSquare = false;
                if (enPassantTarget != null && 
                    row == enPassantTarget![0] && 
                    col == enPassantTarget![1]) {
                  isSpecialSquare = true;
                }

                return Square(
                  isBlack: isBlack(index),
                  piece: board[row][col],
                  isSelected: selectedRow == row && selectedCol == col, // Check if the square is selected
                  onTap: () {
                    pieceSelected(row, col); // Handle piece selecting
                  },
                  isValidMove: isValidMove,
                  isSpecialSquare: isSpecialSquare,
                );
              },
            ),
          ),
          // Turn indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isblackturn ? "Black's Turn" : "White's Turn",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Reset button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initializeBoard();
                    selectedPiece = null;
                    selectedRow = -1;
                    selectedCol = -1;
                    validmoves = [];
                    isblackturn = false;
                    whitePieces = [];
                    blackPieces = [];
                    BKP = [0, 4];
                    WKP = [7, 4];
                    ischeck = false;
                    isCheckmate = false;
                    whiteKingMoved = false;
                    blackKingMoved = false;
                    whiteRookAMoved = false;
                    whiteRookHMoved = false;
                    blackRookAMoved = false;
                    blackRookHMoved = false;
                    enPassantTarget = null;
                  });
                },
                child: const Text("Reset Game"),
              ),
            ],
          ),
          // Declaring the pieces for black
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blackPieces.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => Deadpieces(
                imagepath: blackPieces[index].imagePath,
                isBlack: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}