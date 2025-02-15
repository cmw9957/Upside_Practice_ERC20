// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    bytes32 private constant TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    address private immutable cachedThis;
    bytes32 private immutable hashedName;

    bytes32 private domainSeparator;
    bytes32 private hashedVersion;
    uint256 private chainId;

    string private name;
    string private version;
    string private symbol;

    address owner;
    uint256 public totalSupply = 1_000_000 * decimals();
    bool paused = false;

    mapping(address => uint256) balances;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        version = "1";
        symbol = _symbol;
        owner = msg.sender;

        hashedName = keccak256(bytes(_name));
        hashedVersion = keccak256(bytes("1"));

        chainId = block.chainid;
        domainSeparator = buildDomainSeparator();
        cachedThis = address(this);
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

    function decimals() internal pure returns (uint256) {
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

    function _domainSeparator() internal view returns (bytes32) {
        if (address(this) == cachedThis && block.chainid == chainId) {
            return domainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    function buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, hashedName, hashedVersion, block.chainid, address(this)));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return toTypedDataHash(_domainSeparator(), structHash);
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address recovered) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        address signer = ecrecover(hash, v, r, s);

        return signer;
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        address recovered = tryRecover(hash, v, r, s);
        return recovered;
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
        address recoveredAddress = recover(digest, v, r, s);

        require(recoveredAddress == _owner, "INVALID_SIGNER");

        allowance[_owner][_spender] += _value;
    }

    function upgradeVersion(string memory newVersion) external onlyOwner {
        version = newVersion;
        hashedVersion = keccak256(bytes(newVersion));
        domainSeparator = _domainSeparator();
    }
}