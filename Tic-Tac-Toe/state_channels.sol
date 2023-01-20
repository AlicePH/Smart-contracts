// SPDX-License-Identifier: MIT

//X -sign for the first player, O - sign of the second player, and * if the field is Empty
//there can be any bet amount, even 0, but the first player defines it

pragma solidity ^0.4.26;

contract Game {
    
    address private player1; //puts "X"
    address private player2; //puts "O"
    uint256 public betAmount; //first player can make any bet
    bool private gameOver;
    int private board_x=0;
    int private board_o=0;
    address public gameWinner;

    address private owner;
    uint new_nonce=0;


    enum SquareState {Empty, X, O}
    SquareState[3][3] board;


    struct GameState {
        uint8 nonce;

        bytes32 player1commit_row_1;
        bytes32 player1commit_row_2;
        bytes32 player1commit_row_3;

        bytes32 player2commit_row_1;
        bytes32 player2commit_row_2;
        bytes32 player2commit_row_3;
    }

    GameState private state;
    uint256 private timeoutInterval=1000; //time to wait
    uint256 private timeout; // time when some actions start (time now+timeoutInterval)
    bytes32 private player1move;
    bytes32 private player2move;
    mapping (address => uint) private payments;


    bytes32 private temp1=0x5800000000000000000000000000000000000000000000000000000000000000; //X
    bytes32 private temp2=0x4f00000000000000000000000000000000000000000000000000000000000000; //O
    bytes32 private temp3=0x2a00000000000000000000000000000000000000000000000000000000000000; //*


    constructor() public payable { 
        player1 = msg.sender;
        betAmount = msg.value;
    }


    function join() public payable {
        require(player2 == address(0), "Game has already started.");
        require(player1 != msg.sender, "The game owner cannot join their own game");
        require(!gameOver, "Game was canceled.");
        require(msg.value == betAmount, "Wrong bet amount."); 

        
        player2 = msg.sender;
        timeout = block.timestamp + timeoutInterval;
    }


    function cancel() public {
        require(msg.sender == player1, "Only first player may cancel.");
        require(player2 == address(0), "Game has already started.");

        gameOver = true;
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }


//____________________________________________________________________________________________________________________________
    
    //functions to show board
    function squareToString(uint8 xpos, uint8 ypos) private view returns (string) {
        if(board[xpos][ypos] == SquareState.Empty){
        return " ";
        }
        if(board[xpos][ypos] == SquareState.X) {
        return "X";
        }
        if(board[xpos][ypos] == SquareState.O) {
        return "O";
        }
    }

    function rowToString(uint8 ypos) private view returns (string) {
        return string (abi.encodePacked(squareToString(0, ypos), "|", squareToString(1, ypos), "|", squareToString(2, ypos)));
    }
    function Board() public view returns (string) {
        return string(abi.encodePacked("\n",
            rowToString(0), "\n",
            rowToString(1), "\n",
            rowToString(2), "\n"));
    }
//____________________________________________________________________________________________________________________________
   
    function move(uint8 nonce, string memory _row_1, string memory _row_2, string memory _row_3) public {
        bytes32 row_1=stringToBytes32(_row_1);
        bytes32 row_2=stringToBytes32(_row_2);
        bytes32 row_3=stringToBytes32(_row_3);
        
        state.nonce=nonce;

        require(msg.sender == player1, "Only first player may commit, but you can disagree with submission later.");
        require (player2 != address(0), "Second player did not join");
        require(!gameOver, "Game has ended.");
        require(block.timestamp < timeout, "Moves closed"); // Only allow commits during committing period

        state.player1commit_row_1 = row_1;
        state.player1commit_row_2 = row_2;
        state.player1commit_row_3 = row_3;


        board[0][0]=bytes_to_squarestate(row_1[0]);
        board[0][1]=bytes_to_squarestate(row_1[1]);
        board[0][2]=bytes_to_squarestate(row_1[2]);

        board[1][0]=bytes_to_squarestate(row_2[0]);
        board[1][1]=bytes_to_squarestate(row_2[1]);
        board[1][2]=bytes_to_squarestate(row_2[2]);

        board[2][0]=bytes_to_squarestate(row_3[0]);
        board[2][1]=bytes_to_squarestate(row_3[1]);
        board[2][2]=bytes_to_squarestate(row_3[2]);

    }

    function bytes_to_squarestate(bytes32 symbol) private view returns (SquareState result) {
        if (symbol == temp1) return SquareState.X;
        if (symbol == temp2) return SquareState.O;
        if (symbol == temp3) return SquareState.Empty;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    
    function isGameOver() private view returns (bool) {
        return (winningPlayerShape() != SquareState.Empty);
    }
    

    function winningPlayerShape() private view returns (SquareState result) {
        //Columns
        if (board[0][0] != SquareState.Empty && board[0][0] == board[0][1] && board[0][0] == board[0][2]){
            return board[0][0];
        }
        if (board[1][0] != SquareState.Empty && board[1][0] == board[1][1] && board[1][0] ==board[1][2]){
            return board[1][0];
        }
        
        if (board[2][0] != SquareState.Empty && board[2][0] == board[2][1] && board[2][0] == board[2][2]){
            return board[2][0];
        }

        //Rows

        if (board[0][0] != SquareState.Empty && board[0][0] == board[1][0] && board[0][0] == board[2][0]){
            return board[0][0];
        }
        if (board[0][1] != SquareState.Empty && board[0][1] == board[1][1] && board[0][1] ==board[2][1]){
            return board[0][1];
        }
        
        if (board[0][2] != SquareState.Empty && board[0][2] == board[1][2] && board[0][2] == board[2][2]){
            return board[0][2];
        }


        //Diagonal
        if (board[0][0] != SquareState.Empty && board[0][0] == board[1][1] && board[0][0] == board[2][2]){
            return board[0][0];
        }
        if (board[0][2] != SquareState.Empty && board[0][2] == board[1][1] && board[0][2] ==board[2][0]){
            return board[0][2];
        }

    }

    function winner() private {
        //require (isGameOver(), "Game is not over");
        board_x=0;
        board_o=0;
        
        for(uint i=0; i<3; i++){
            for(uint j=0; j<3; j++){
                if(board[i][j] == SquareState.X) board_x+=1;
                if(board[i][j] == SquareState.O) board_o+=1;
            }
        }

        require(abs(board_x-board_o)<2, "Wrong and impossible combination, submit again");
        require(isGameOver(), "Game is not over, submit the latest version of game");

        SquareState winning_shape = winningPlayerShape();
        if(winning_shape == SquareState.X) {
            gameWinner=player1;
        } 
        else {
            if (winning_shape == SquareState.O) {
                gameWinner=player2;
            }
        }
        gameWinner=0x0; //in case of draw returns 0x0
    }

    function argue(uint8 nonce, string memory _row_1, string memory _row_2, string memory _row_3) public {
        bytes32 row_1=stringToBytes32(_row_1);
        bytes32 row_2=stringToBytes32(_row_2);
        bytes32 row_3=stringToBytes32(_row_3);
        
        require (nonce > state.nonce, "You don't have the latest version of game");
        state.nonce=nonce;

        require(msg.sender == player2, "Only second player can argue");
        require(block.timestamp < timeout, "Moves closed"); // Only allow commits during committing period

        state.player2commit_row_1 = row_1;
        state.player2commit_row_2 = row_2;
        state.player2commit_row_3 = row_3;


        board[0][0]=bytes_to_squarestate(row_1[0]);
        board[0][1]=bytes_to_squarestate(row_1[1]);
        board[0][2]=bytes_to_squarestate(row_1[2]);

        board[1][0]=bytes_to_squarestate(row_2[0]);
        board[1][1]=bytes_to_squarestate(row_2[1]);
        board[1][2]=bytes_to_squarestate(row_2[2]);

        board[2][0]=bytes_to_squarestate(row_3[0]);
        board[2][1]=bytes_to_squarestate(row_3[1]);
        board[2][2]=bytes_to_squarestate(row_3[2]);

        new_nonce=1;

    }

    function take_money() public { 
        owner=gameWinner; 
        require (isGameOver(), "Game is not over");
        require (block.timestamp > timeout || new_nonce == 1, "Time to argue with the first submission");
        require (msg.sender == owner || owner == address(0), "You did not win");

        if (isGameOver()) {
            //if after this move game stopped, it means that this player won and money will be transfered automatically
            owner=gameWinner; 
            if (owner != 0x0) {
                owner.transfer(address(this).balance);
            }
            else {
                player1.transfer(betAmount);
                player2.transfer(betAmount);
            }
            
        }
    }

}
