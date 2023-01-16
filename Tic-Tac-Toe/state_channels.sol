// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Game {
    
    address private player1; //puts "X"
    address private player2; //puts "O"
    address public gameWinner;
    uint256 private betAmount = 1/uint256(2);
    bool private gameOver;


    struct GameState {
        uint8 nonce;

        bytes32 player1commit_row_1;
        bytes32 player1commit_row_2;
        bytes32 player1commit_row_3;

        bytes32 player2commit_row_1;
        bytes32 player2commit_row_2;
        bytes32 player2commit_row_3;

        address whoseTurn;
    }

    GameState private state;
    uint256 private timeoutInterval=1000;
    uint256 private timeout = 2**256 - 1;
    bytes32 private player1move;
    bytes32 private player2move;


    constructor() payable { 
        player1 = msg.sender;
        betAmount = msg.value;
    }

    function join() public payable {
        require(player2 == address(0), "Game has already started.");
        require(player1 != msg.sender, "The game owner cannot join their own game");
        require(!gameOver, "Game was canceled.");
        require(msg.value == betAmount, "Wrong bet amount.");

        player2 = msg.sender;
        state.whoseTurn = player1;
        timeout = block.timestamp + timeoutInterval;
    }

    function cancel() public {
        require(msg.sender == player1, "Only first player may cancel.");
        require(player2 == address(0), "Game has already started.");

        gameOver = true;
        payable(msg.sender).transfer(address(this).balance);
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

    function move(uint8 nonce, string memory _row_1, string memory _row_2, string memory _row_3) public {
        bytes32 row_1=stringToBytes32(_row_1);
        bytes32 row_2=stringToBytes32(_row_2);
        bytes32 row_3=stringToBytes32(_row_3);
        state.nonce=9;
        
        require(!gameOver, "Game has ended.");
        require(msg.sender == state.whoseTurn, "Not your turn.");
        require(state.nonce == nonce, "Incorrect nonce number.");
        require(block.timestamp < timeout, "Moves closed"); // Only allow commits during committing period

        if (msg.sender == player1) {
            require(
            (state.player1commit_row_1 == bytes32(0)) &&
            (state.player1commit_row_2 == bytes32(0)) &&
            (state.player1commit_row_3 == bytes32(0)), "you have already moved!");

            state.player1commit_row_1 = row_1;
            state.player1commit_row_2 = row_2;
            state.player1commit_row_3 = row_3;
        } else {
            require(
            (state.player2commit_row_1 == bytes32(0)) &&
            (state.player2commit_row_2 == bytes32(0)) &&
            (state.player2commit_row_3 == bytes32(0)), "you have already moved!");

            state.player2commit_row_1 = row_1;
            state.player2commit_row_2 = row_2;
            state.player2commit_row_3 = row_3;
        }

        state.whoseTurn = opponentOf(msg.sender);
    }

    function opponentOf(address player) internal view returns (address) {
        require(player2 != address(0), "Game has not started.");

        if (player == player1) {
            return player2;
        } else if (player == player2) {
            return player1;
        } else {
            revert("Invalid player.");
        }
    }

}
