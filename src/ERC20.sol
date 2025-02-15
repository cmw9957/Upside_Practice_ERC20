// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    string name;
    string symbol;

    address owner;
    uint256 public constant totalSupply = 1_000_000 * decimal();
    bool paused = false;

    mapping(address => uint256) balances;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner.");
        _;
    }

    modifier isNotPause() {
        require(!paused, "Paused now.");
        _;
    }

    modifier isExpire(uint256 deadline) {
        require(block.timestamp <= deadline, "Signature expired");
        _;
    }

    modifier isSupplySufficient(uint256 amount) {
        require(totalSupply >= amount, "totalSupply insufficient.");
        _;
    }

    function decimal() internal {
        return 10**18;
    }

    function transfer(address _to, uint256 _amount) public payable isNotPause() isSupplySufficient(_amount) {
        totalSupply -= _amount;
        balances[_to] += _amount;
    }

    function pause() public onlyOwner() {
        paused = true;
    }

    function approve(address _spender, uint256 _amount) public payable {
        allowance[msg.sender][_spender] += _amount;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public payable isNotPause() {
        allowance[msg.sender][_from] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) public isExpire(_deadline) {
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            _owner,
            _spender,
            _value,
            nonces[_owner]++,
            _deadline
        ));

        bytes32 digest = _toTypedDataHash(structHash);
        address recoveredAddress = ECDSA.recover(digest, v, r, s);

        require(recoveredAddress == _owner, "INVALID_SIGNER");

        allowance[_owner][_spender] += _value;
    }
}