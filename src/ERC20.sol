// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    // EIP-712 Domain Separator 관련 타입 해시 (EIP-712 표준의 도메인 정보를 해시화)
    bytes32 private constant TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // 현재 컨트랙트의 주소를 저장 (immutable)
    address private immutable cachedThis;
    // 토큰 이름의 해시값
    bytes32 private immutable hashedName;

    // EIP-712 도메인 구분자, 도메인과 구조체 해시 결합 시 사용
    bytes32 private domainSeparator;
    // version의 해시값 (EIP-712 도메인에 사용)
    bytes32 private hashedVersion;
    // 현재 체인의 ID
    uint256 private chainId;

    // ERC-20 토큰 이름, 버전, 심볼
    string private name;
    string private version;
    string private symbol;

    address owner;
    // 총 공급량 (1,000,000 * 10^18)
    uint256 public totalSupply = 1_000_000 * decimals();
    // 현재 컨트랙트 상태가 정지 여부인지 확인
    bool paused = false;

    // 각 주소에 대한 잔액
    mapping(address => uint256) balances;
    // 각 주소에 대한 논스 (중복된 서명을 방지하기 위해 사용)
    mapping(address => uint256) public nonces;
    // 각 주소 간 허용된 송금량 (permit)
    mapping(address => mapping(address => uint256)) public allowance;

    // 토큰의 이름, 심볼을 설정하고, 체인 ID 및 도메인 구분자를 초기화
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

    // owner로 권한 제한
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner.");
        _;
    }

    // pause되지 않은 경우
    modifier isNotPause() {
        require(!paused, "Paused now.");
        _;
    }

    // 서명 만료 시간을 확인
    modifier isExpire(uint256 deadline) {
        require(block.timestamp <= deadline, "Signature expired");
        _;
    }

    // 공급량이 충분한지 확인
    modifier isSupplySufficient(uint256 amount) {
        require(totalSupply >= amount, "totalSupply insufficient.");
        _;
    }

    // 토큰의 소수점 자릿수 설정
    function decimals() internal pure returns (uint256) {
        return 10**18;
    }

    // 토큰 송금 함수 (pause와 공급량 확인 포함)
    function transfer(address _to, uint256 _amount) public payable isNotPause() isSupplySufficient(_amount) {
        totalSupply -= _amount;
        balances[_to] += _amount;
    }

    // 컨트랙트 정지 함수 (owner 권한)
    function pause() public onlyOwner() {
        paused = true;
    }

    // 특정 spender 승인 함수
    function approve(address _spender, uint256 _amount) public payable {
        allowance[msg.sender][_spender] += _amount;
    }

    // approve 후, 대리 송금 함수
    function transferFrom(address _from, address _to, uint256 _amount) public payable isNotPause() {
        require(allowance[msg.sender][_from] >= _amount, "Not enough amount or No allowance.");
        allowance[msg.sender][_from] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    // domain separator 반환 함수, chain id 변경 여부 확인 포함
    function _domainSeparator() internal view returns (bytes32) {
        if (address(this) == cachedThis && block.chainid == chainId) {
            return domainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    // EIP-712 domain separator 생성 함수
    function buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, hashedName, hashedVersion, block.chainid, address(this)));
    }

    // EIP-712 구조체 hash로 type data hash 생성
    function toTypedDataHash(bytes32 domainSepa, bytes32 structHash) internal pure returns (bytes32 digest) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSepa)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }

    // type data hash 반환
    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        return toTypedDataHash(_domainSeparator(), structHash);
    }

    // 서명을 복구하여 서명자의 주소를 반환
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

    // 서명자의 주소 복구 (복구 실패 시 주소 0 반환)
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return tryRecover(hash, v, r, s);
    }

    // 서명된 메시지를 통해 spender에게 토큰을 승인
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

    // version upgrade 함수 (owner 권한)
    function upgradeVersion(string memory newVersion) external onlyOwner {
        version = newVersion;
        hashedVersion = keccak256(bytes(newVersion));
        domainSeparator = _domainSeparator();
    }
}
