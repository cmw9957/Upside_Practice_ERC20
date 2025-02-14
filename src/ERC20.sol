// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract ERC20 is EIP712 {
    string name;
    string symbol;

    address owner;

    bool isPause = false;

    uint256 totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    constructor (string memory _name, string memory _symbol) EIP712(_name, _symbol) {
        name = _name;
        symbol = _symbol;

        owner = msg.sender;
        totalSupply = 10000 ether;
    }

    function transfer(address _to, uint256 _amount) public payable {
        require(!isPause, "Paused now.");
        require(totalSupply >= _amount, "totalSupply insufficient.");

        totalSupply -= _amount;
        balances[_to] += _amount;
    }

    function pause() public {
        require(msg.sender == owner, "You are not owner.");
        isPause = true;
    }

    function approve(address _spender, uint256 _amount) public payable {
        allowance[msg.sender][_spender] += _amount;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public payable {
        require(isPause, "Paused now.");
        
        allowance[msg.sender][_from] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function permit(address _owner, address _spender, uint256 _value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {

    }
}