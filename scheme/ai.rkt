#lang racket

;; ai.rkt
;; Entry point for the Scheme-based chess AI.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. Search depth
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Controls how far the minimax search looks ahead (in plies).
;; Lower values make the AI faster but weaker, higher values slow it down.
(define SEARCH-DEPTH 3)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. Command-line parsing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Color of the side to move, as a string ("white" or "black").
(define color-str #f)
;; 64-character board string passed from C++.
(define board-str #f)
;; List of root moves the AI is allowed to choose from.
(define root-moves '())

;; Read arguments from the command line and initialize the above variables.
(command-line
 #:program "ai.rkt"
 #:args args
 (cond
   ;; If not enough arguments are given, signal that no move can be chosen.
   [(< (length args) 3)
    (displayln "NONE")
    (exit 0)]
   ;; Otherwise, fill in color, board, and the move list.
   [else
    (set! color-str (list-ref args 0))
    (set! board-str (list-ref args 1))
    (set! root-moves (drop args 2))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. Board representation utilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The board is represented as a flat 64-character string.
;; Index 0 is the top-left square (a8) and index 63 is the bottom-right (h1).
(define (make-board s) s)

;; Convert (row, col) coordinates into a string index.
;; row 0 is rank 1, row 7 is rank 8.
;; index = (7 - row) * 8 + col
(define (square-index row col)
  (+ (* (- 7 row) 8) col))

;; Read the character at a given board position.
(define (board-get board row col)
  (string-ref board (square-index row col)))

;; Return a new board string with one square replaced by a given character.
(define (board-set board row col ch)
  (define idx (square-index row col))
  (define len (string-length board))
  (define new (make-string len))
  (for ([i (in-range len)])
    (string-set! new i (if (= i idx)
                           ch
                           (string-ref board i))))
  new)

;; Check whether a pair of coordinates lies inside the 8x8 board.
(define (on-board? row col)
  (and (<= 0 row) (< row 8)
       (<= 0 col) (< col 8)))

;; Check whether a square is empty (contains '.').
(define (empty-square? board row col)
  (and (on-board? row col)
       (char=? (board-get board row col) #\.)))

;; Determine the color of a piece based on its character.
;; Uppercase means white, lowercase means black, '.' means none.
(define (piece-color ch)
  (cond
    [(char=? ch #\.) 'none]
    [(char<=? #\A ch #\Z) 'white]
    [(char<=? #\a ch #\z) 'black]
    [else 'none]))

;; Normalize piece type to uppercase so logic can ignore color.
(define (piece-type ch)
  (char-upcase ch))

;; Return the opposite color symbol.
(define (opponent-color c)
  (cond
    [(eq? c 'white) 'black]
    [(eq? c 'black) 'white]
    [else 'none]))

;; Check whether a square holds a piece that belongs to the other side.
(define (opponent-piece? board row col color)
  (let ([ch (board-get board row col)])
    (and (not (char=? ch #\.))
         (not (eq? (piece-color ch) color))
         (not (eq? (piece-color ch) 'none)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 4. Move parsing & applying ("e2e4")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Convert a file letter ('a'..'h') to a zero-based column.
(define (file-char->col ch)
  (- (char->integer ch) (char->integer #\a)))

;; Convert a rank character ('1'..'8') to a zero-based row.
(define (rank-char->row ch)
  (- (char->integer ch) (char->integer #\1)))

;; Convert a move string like "e2e4" into numeric coordinates.
;; Returns (from-row from-col to-row to-col).
(define (parse-move-str m)
  (define from-file (file-char->col (string-ref m 0)))
  (define from-rank (rank-char->row (string-ref m 1)))
  (define to-file   (file-char->col (string-ref m 2)))
  (define to-rank   (rank-char->row (string-ref m 3)))
  (list from-rank from-file to-rank to-file))

;; Convert numeric coordinates back into a move string like "e2e4".
(define (coords->move-str fr fc tr tc)
  (define from-file (integer->char (+ (char->integer #\a) fc)))
  (define from-rank (integer->char (+ (char->integer #\1) fr)))
  (define to-file   (integer->char (+ (char->integer #\a) tc)))
  (define to-rank   (integer->char (+ (char->integer #\1) tr)))
  (list->string (list from-file from-rank to-file to-rank)))

;; Apply a move string to a board and return the resulting new board.
(define (apply-move board move-str)
  (define coords (parse-move-str move-str))
  (define fr (list-ref coords 0))
  (define fc (list-ref coords 1))
  (define tr (list-ref coords 2))
  (define tc (list-ref coords 3))
  (define piece (board-get board fr fc))
  (define board1 (board-set board fr fc #\.))
  (define board2 (board-set board1 tr tc piece))
  board2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. Move generation (pseudo-legal)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Get the forward movement direction for a pawn of the given color.
(define (pawn-dir color)
  (if (eq? color 'white) 1 -1))

;; Get the starting row for pawns of a given color.
(define (start-rank color)
  (if (eq? color 'white) 1 6))

;; Check basic pawn moves: single push, double push from start, and captures.
(define (valid-pawn-move? board color fr fc tr tc)
  (define dir (pawn-dir color))
  (define forward-row (+ fr dir))
  (cond
    ;; Single forward move into an empty square
    [(and (= tr forward-row)
          (= tc fc)
          (empty-square? board tr tc))
     #t]
    ;; Double forward move from the starting rank if both squares are empty
    [(and (= fr (start-rank color))
          (= tr (+ fr (* 2 dir)))
          (= tc fc)
          (empty-square? board forward-row tc)
          (empty-square? board tr tc))
     #t]
    ;; Diagonal capture move onto an opponent's piece
    [(and (= tr forward-row)
          (or (= tc (+ fc 1)) (= tc (- fc 1)))
          (opponent-piece? board tr tc color))
     #t]
    ;; Anything else is not a valid pawn move
    [else #f]))

;; Check if a knight move follows the L-shaped pattern.
(define (valid-knight-move? fr fc tr tc)
  (define dr (abs (- tr fr)))
  (define dc (abs (- tc fc)))
  (or (and (= dr 2) (= dc 1))
      (and (= dr 1) (= dc 2))))

;; Return the sign of a number as -1, 0, or 1.
(define (signum x)
  (cond [(> x 0) 1]
        [(< x 0) -1]
        [else 0]))

;; Check that every square between the start and end is empty.
;; Used by sliding pieces (rooks, bishops, queens).
(define (path-clear? board fr fc tr tc)
  (define dr (signum (- tr fr)))
  (define dc (signum (- tc fc)))
  (define start-r (+ fr dr))
  (define start-c (+ fc dc))
  (let loop ([r start-r] [c start-c])
    (cond
      ;; Reached the destination without finding a blocking piece
      [(and (= r tr) (= c tc)) #t]
      ;; Hit a non-empty square on the way
      [(not (empty-square? board r c)) #f]
      ;; Step along the path and keep checking
      [else (loop (+ r dr) (+ c dc))])))

;; Check rook-like moves (along ranks or files).
(define (valid-rook-move? board fr fc tr tc)
  (and (or (= fr tr) (= fc tc))
       (not (and (= fr tr) (= fc tc)))
       (path-clear? board fr fc tr tc)))

;; Check bishop-like moves (along diagonals).
(define (valid-bishop-move? board fr fc tr tc)
  (define dr (abs (- tr fr)))
  (define dc (abs (- tc fc)))
  (and (> dr 0)
       (= dr dc)
       (path-clear? board fr fc tr tc)))

;; Check queen moves, which combine rook and bishop movement.
(define (valid-queen-move? board fr fc tr tc)
  (or (valid-rook-move? board fr fc tr tc)
      (valid-bishop-move? board fr fc tr tc)))

;; Check king moves that stay within one square in any direction.
(define (valid-king-move? fr fc tr tc)
  (define dr (abs (- tr fr)))
  (define dc (abs (- tc fc)))
  (and (<= dr 1) (<= dc 1)
       (not (and (= dr 0) (= dc 0)))))

;; Validate a move by checking board bounds, ownership, and specific piece rules.
(define (valid-move? board color fr fc tr tc)
  (and (on-board? tr tc)
       (on-board? fr fc)
       (let ([from-ch (board-get board fr fc)]
             [to-ch   (board-get board tr tc)])
         (and (not (char=? from-ch #\.))
              (eq? (piece-color from-ch) color)
              (or (char=? to-ch #\.)
                  (opponent-piece? board tr tc color))
              (let ([ptype (piece-type from-ch)])
                (cond
                  [(char=? ptype #\P)
                   (valid-pawn-move? board color fr fc tr tc)]
                  [(char=? ptype #\N)
                   (valid-knight-move? fr fc tr tc)]
                  [(char=? ptype #\B)
                   (valid-bishop-move? board fr fc tr tc)]
                  [(char=? ptype #\R)
                   (valid-rook-move? board fr fc tr tc)]
                  [(char=? ptype #\Q)
                   (valid-queen-move? board fr fc tr tc)]
                  [(char=? ptype #\K)
                   (valid-king-move? fr fc tr tc)]
                  [else #f]))))))

;; Generate all pseudo-legal moves for a given side (ignores checks on the king).
(define (generate-pseudo-legal-moves board color)
  (for*/list ([fr (in-range 0 8)]
              [fc (in-range 0 8)]
              [tr (in-range 0 8)]
              [tc (in-range 0 8)]
              #:when (valid-move? board color fr fc tr tc))
    (coords->move-str fr fc tr tc)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Return the material value of a single piece character.
;; White pieces contribute positive values, black pieces negative ones.
(define (piece-value ch)
  (cond
    [(char=? ch #\P) 100]
    [(char=? ch #\N) 320]
    [(char=? ch #\B) 330]
    [(char=? ch #\R) 500]
    [(char=? ch #\Q) 900]
    [(char=? ch #\K) 20000]
    [(char=? ch #\p) -100]
    [(char=? ch #\n) -320]
    [(char=? ch #\b) -330]
    [(char=? ch #\r) -500]
    [(char=? ch #\q) -900]
    [(char=? ch #\k) -20000]
    [else 0]))

;; Convert a string index back into (row, col) coordinates.
(define (index->row-col idx)
  (define col (remainder idx 8))
  (define row (- 7 (quotient idx 8)))
  (values row col))

;; Score how central a square is: center squares get higher scores.
(define (center-score row col)
  (define dist (+ (abs (- row 3)) (abs (- col 3))))
  (max 0 (- 4 dist)))

;; Compute a positional bonus for a piece based on square and color.
;; sign is +1 for white pieces, -1 for black pieces.
(define (positional-bonus ch row col sign)
  (define t (piece-type ch))
  (define c (center-score row col))
  (cond
    [(char=? t #\P) (* sign c 2)]
    [(char=? t #\N) (* sign c 10)]
    [(char=? t #\B) (* sign c 6)]
    [(char=? t #\R) (* sign c 2)]
    [(char=? t #\Q) (* sign c 2)]
    [(char=? t #\K) (* sign (- 2 c))]
    [else 0]))

;; Evaluate the whole board from White's perspective (positive is better for White).
;; Material and positional bonuses are both included in the score.
(define (evaluate-board board)
  (define len (string-length board))
  (let loop ([i 0] [score 0])
    (if (= i len)
        score
        (let* ([ch (string-ref board i)]
               [base (piece-value ch)])
          (if (char=? ch #\.)
              (loop (add1 i) score)
              (let-values ([(row col) (index->row-col i)])
                (define color (piece-color ch))
                (define sign
                  (cond [(eq? color 'white) 1]
                        [(eq? color 'black) -1]
                        [else 0]))
                (define pos (positional-bonus ch row col sign))
                (loop (add1 i) (+ score base pos))))))))

;; Convert a color string into a symbol used in the logic.
(define (side-symbol color-str)
  (if (string-ci=? color-str "white") 'white 'black))

;; Adjust the evaluation so that it is always from the root side's perspective.
(define (score-from-root board root-side)
  (define s (evaluate-board board))
  (if (eq? root-side 'white) s (- s)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. Minimax with alpha–beta pruning
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Values used as "infinite" bounds for alpha and beta.
(define +INF  1000000000)
(define -INF -1000000000)

;; Minimax search with alpha–beta pruning.
;; board      : current board position
;; side       : side to move at this node
;; depth      : remaining search depth
;; alpha/beta : current best bounds for pruning
;; maximizing?: #t if this node should maximize the score, #f to minimize
;; root-side  : side the evaluation is ultimately from (the AI's side)
(define (minimax board side depth alpha beta maximizing? root-side)
  (cond
    ;; At depth 0, stop searching and evaluate the position.
    [(<= depth 0)
     (score-from-root board root-side)]
    [else
     ;; Generate pseudo-legal moves for the side to move.
     (define moves (generate-pseudo-legal-moves board side))
     ;; If there are no moves, evaluate the static position.
     (if (null? moves)
         (score-from-root board root-side)
         (if maximizing?
             ;; Maximizing node: try to make the score as large as possible.
             (let loop ([ms moves] [value -INF] [a alpha])
               (if (null? ms)
                   value
                   (let* ([m (car ms)]
                          [child (apply-move board m)]
                          [score (minimax child
                                          (opponent-color side)
                                          (sub1 depth)
                                          a beta
                                          #f
                                          root-side)]
                          [new-value (max value score)]
                          [new-alpha (max a new-value)])
                     (if (>= new-alpha beta)
                         ;; Beta cut-off: the minimizing side already has a better option.
                         new-value
                         (loop (cdr ms) new-value new-alpha)))))
             ;; Minimizing node: try to make the score as small as possible.
             (let loop ([ms moves] [value +INF] [b beta])
               (if (null? ms)
                   value
                   (let* ([m (car ms)]
                          [child (apply-move board m)]
                          [score (minimax child
                                          (opponent-color side)
                                          (sub1 depth)
                                          alpha b
                                          #t
                                          root-side)]
                          [new-value (min value score)]
                          [new-beta (min b new-value)])
                     (if (<= new-beta alpha)
                         ;; Alpha cut-off: the maximizing side already has a better option.
                         new-value
                         (loop (cdr ms) new-value new-beta)))))))]))

;; Pick the best move at the root by running minimax on each candidate move.
(define (best-move board root-side root-moves)
  ;; Start with the first move as a default best.
  (define best-mv (car root-moves))
  (define best-val -INF)
  ;; Evaluate each move and keep track of the one with the highest score.
  (for ([m (in-list root-moves)])
    (define child (apply-move board m))
    (define score (minimax child
                           (opponent-color root-side)
                           (sub1 SEARCH-DEPTH)
                           -INF +INF
                           #f
                           root-side))
    (when (> score best-val)
      (set! best-val score)
      (set! best-mv m)))
  best-mv)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. Main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Main entry point: choose a move and print it for the C++ side to read.
(define (main)
  (define board (make-board board-str))
  (define root-side (side-symbol color-str))
  (cond
    ;; If there are no candidate moves, print "NONE".
    [(null? root-moves)
     (displayln "NONE")]
    ;; Otherwise, compute the best move and print it.
    [else
     (define mv (best-move board root-side root-moves))
     (displayln mv)]))

(main)
