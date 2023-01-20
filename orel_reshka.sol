//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract orel_reshka {
    address payable public owner;

    address public player1 = address(0);
    address public player2 = address(0);

    uint256 public betAmount=500000000000000000;
    uint256 public comission=50000000000000000;

    bool public player1Choice;
    bool public player2Choice;
    bool private gameComplete;
    address payable public winner;
    uint number_of_play=0;

    mapping (uint => string) public winner_answers;

    constructor() payable{
        owner = payable(msg.sender);
    }

    function join() public payable {
        require(player1 == address(0) || player2 == address(0), "Game has already started.");
        require(msg.value == betAmount, "Wrong bet amount."); 
        require(owner != payable(msg.sender), "The game owner can not join their own game");

        if (player1 == address(0)){
            player1=msg.sender;
        }
        else if (player2 == address(0) && player1!=msg.sender) player2=msg.sender;
        owner.transfer(comission);
    }

    

    function placeBet(bool _playerChoice) public {
        //1 means orel, 0 means reshka
        require(msg.sender == player1 || msg.sender == player2);
        require(!gameComplete);

        if (msg.sender == player1) {
            player1Choice = _playerChoice;
        } else if (msg.sender == player2) {
            if (player1Choice){
                player2Choice = false;
            } 
            else{
                player2Choice = true;   
            }
        }
    }

    function flipCoin() public {
        require(msg.sender == owner);
        require(!(player1Choice && player2Choice));
        gameComplete = true;

        if (keccak256(abi.encodePacked(block.timestamp)) > keccak256(abi.encodePacked(block.timestamp/2))) {
            if (player1Choice) {
                winner = payable(player1); 
                if (player1Choice) winner_answers[number_of_play]="orel";
                else winner_answers[number_of_play]="reshka";
                
            } 
            else {
                winner = payable(player2);
                if (player2Choice) winner_answers[number_of_play]="orel";
                else winner_answers[number_of_play]="reshka";
            }
        } 
        
        else {
            if (player1Choice) {
                winner = payable(player2);
                if (player2Choice) winner_answers[number_of_play]="orel";
                else winner_answers[number_of_play]="reshka";
            } 
            else {
                winner = payable(player1);
                if (player1Choice) winner_answers[number_of_play]="orel";
                else winner_answers[number_of_play]="reshka";
            }
        }
        winner.transfer(2 * (betAmount-comission));
        

        gameComplete = false;
        player1 = address(0);
        player2 = address(0);
        number_of_play+=1;
    }

    
}
