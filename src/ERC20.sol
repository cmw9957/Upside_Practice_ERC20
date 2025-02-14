contract ERC20 {
    string name;
    string symbol;

    address owner;

    bool isPause = false;

    uint256 totalSupply;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        owner = msg.sender;
        totalSupply = 10000 ether;
    }

    function transfer(address _to, uint256 _amount) public payable {
        require(isPause, "Paused now.");
        bool success = payable(_to).send(_amount);
        require(success, "ETH transfer failed.");
    }

    function pause() public {
        require(msg.sender != owner, "You are not owner.");
        isPause = true;
    }

    function approve(address _spender, uint256 _amount) public payable {

    }

    function transferFrom(address _from, address _to, uint256 _amount) public payable {

    }
}