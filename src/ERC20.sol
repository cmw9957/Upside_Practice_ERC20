contract ERC20 {
    string name;
    string symbol;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address _to, uint256 value) public payable {

    }

    function pause() public {

    }

    function approve(address _to, uint256 value) public payable {

    }

    function transferFrom(address _from, address _to, uint256 value) public payable {

    }
}