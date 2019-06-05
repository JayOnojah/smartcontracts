pragma solidity ^0.5.1;

contract Lottery {
    address payable[] public players; // Dynamic array with players addresses
    address public manager; // Contract Manager
    
    constructor () public {
        manager = msg.sender;
    }
    
    // This fallback payable function will be automatically called when somebody sends ether
    function () payable external {
        require(msg.value >= 0.01 ether);
        players.push(msg.sender); // Adds address of the account that sends ether to the players array
    }
    
    function get_balance() public view returns (uint) {
        require(msg.sender == manager);
        return address(this).balance; // return contract balance
    }
    
    function random() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function selectWinner() public {
        require(msg.sender == manager);
        
        uint r = random();
        
        address payable winner;
        
        uint index = r % players.length;
        winner = players[index];
        
        // Transfer contract balance to the winner address
        winner.transfer(address(this).balance);
        
        players = new address payable[](0); // Resetting the players dynamic array
    }
    
}
