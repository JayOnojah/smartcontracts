pragma solidity ^0.5.1;

contract ERC20Interface {
    
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

contract CryptosToken is ERC20Interface {
    
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    constructor () public {
        supply = 1000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
    function allowance(address tokenOwner, address spender) view public returns(uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns(bool) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;
        
        allowed[from][to] -= tokens;
        
        return true;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0);
        
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
}

contract CryptosICO is CryptosToken {
    address public admin;
    address payable public deposit;
    
    // token price in wei: 1 CRPT = 0.001 ETHER, 1 ETHER = 1000 CRPT
    uint tokenPrice = 1000000000000000;
    
    uint public hardCap = 300000000000000000000;
    
    uint public raisedAmount;
    
    uint public salesStart = now;
    uint public salesEnd = now + 604800; // one week
    uint public coinTradeStart = salesEnd + 604800; // transferable in a week after salesEnd
    
    uint public maxInvestment = 5000000000000000000;
    uint public minInvestment = 1000000000000000;
    
    enum State { beforeStart, running, afterEnd, halted }
    State public icoState;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable _deposit) public {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    function halt() public onlyAdmin {
        icoState = State.halted;
    }
    
    // restart
    function unhalt() public onlyAdmin{
        icoState = State.running;
    }
    
    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }
    
    function getCurrentState() public view returns(State) {
        if(icoState == State.halted) {
            return State.halted;
        }else if(block.timestamp < salesStart){
            return State.beforeStart;
        } else if(block.timestamp >= salesStart && block.timestamp <= salesEnd){
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
        // invest only in running
        icoState = getCurrentState();
        require(icoState == State.running);
        
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        uint tokens = msg.value / tokenPrice;
        
        // HradCap not reached
        require(raisedAmount + msg.value <= hardCap);
        
        raisedAmount += msg.value;
        
        // Add tokens to investor balance from founder balance
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value); // Transfer ETH to the deposit address
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
        
    }
    
    function () payable external {
        invest();
    }
    
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
    
}
