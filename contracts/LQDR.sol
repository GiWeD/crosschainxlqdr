// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWERC10.sol";


interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external returns (bool);
}

interface IVault {
    function deposit(address _from, uint256 amount) external  returns(bool);
    function withdraw(address _to, uint256 amount) external  returns(bool);
}

/// @dev Wrapped Ether v10 (WERC10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain an WERC10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WERC10, which will then burn WERC10 token in your wallet. The amount of WERC10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
contract LQDR is IWERC10 {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    uint8  public immutable decimals;

    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant TRANSFER_TYPEHASH = keccak256("Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Records amount of WERC10 token owned by account.
    mapping (address => uint256) public override balanceOf;
    uint256 private _totalSupply;
    
    address private _oldOwner;
    address private _newOwner;
    uint256 private _newOwnerEffectiveTime;

    
    uint256 public chainId;
    uint256 public NATIVECHAIN;
    address public lqdrNativeToken = address(0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9);//ftm testnet 0xb456D55463A84C7A602593D55DB5a808bF46aAc9, mainnet: 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9
    address public lqdrVault;
    
    mapping(address => bool) public minterRegistry; // 


    modifier onlyOwner() {
        require(msg.sender == owner(), "only owner");
        _;
    }

    modifier onlyMinter() {
        require(minterRegistry[msg.sender] == true || msg.sender == owner(), "only Auth");
        _;
    }
    
    function owner() public view returns (address) {
        if (block.timestamp >= _newOwnerEffectiveTime) {
            return _newOwner;
        }
        return _oldOwner;
    }
    
    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping (address => uint256) public override nonces;

    /// @dev Records number of WERC10 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping (address => mapping (address => uint256)) public override allowance;
    
    event LogChangeDCRMOwner(address indexed oldOwner, address indexed newOwner, uint indexed effectiveTime);
    event LogSwapin(bytes32 indexed txhash, address indexed account, uint amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint amount);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner, address _vault) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
        _newOwner = _owner;
        _newOwnerEffectiveTime = block.timestamp;
        
        uint256 _chainId;
        assembly {_chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));

        chainId = _chainId;
        NATIVECHAIN = 250; //250 ftm mainnet, 4002 ftm testnet, 31337 hardhat
        lqdrVault = _vault;
    }


    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "new owner is the zero address");
        _oldOwner = owner();
        _newOwner = newOwner;
        _newOwnerEffectiveTime = block.timestamp + 2*24*3600;
        emit LogChangeDCRMOwner(_oldOwner, _newOwner, _newOwnerEffectiveTime);
        return true;
    }

    function mint(address account, uint256 amount) public onlyMinter returns(bool) {
        // LQDR is not mintable directly from contract, only 0x74 chef has power to mint.
        // If we are on FTM just withdraw from a vault, else mint lqdr
        if(chainId == NATIVECHAIN){
            assert ( IVault(lqdrVault).withdraw(account, amount) );
        } else {
            _mint(account, amount);
        }
        return true;
    }

    function burn(address account, uint256 amount) public onlyMinter returns(bool) {
        require(account != address(0), "AnyswapV3ERC20: address(0x0)");
        // LQDR is not mintable directly from contract, only 0x74 chef has power to mint.
        // If we are on FTM just deposit in a vault, else burn "fake" lqdr
        if(chainId == NATIVECHAIN){
            IERC20(lqdrNativeToken).safeTransferFrom(account, address(this), amount);
            IERC20(lqdrNativeToken).safeApprove(lqdrVault, 0);
            IERC20(lqdrNativeToken).safeApprove(lqdrVault, amount);
            assert ( IVault(lqdrVault).deposit(account, amount) );
        } else {
            _burn(account, amount);
        }
        return true;
    }


    /// @dev minter can call mint/burn. Minter should be anyCallClient, Chainlink CCIP, LayerZeroProxy,... 
    function allowMinter(address _minter) external onlyOwner {
        require(_minter != address(0), 'zero addr');
        require(minterRegistry[_minter] == false, 'already in');
        
        minterRegistry[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        require(_minter != address(0), 'zero addr');
        require(minterRegistry[_minter] == true, 'already in');
        minterRegistry[_minter] = false;
    }


    /// @dev In case we need to move from the native chain to another chain we can deploy a newNativeToken on a newNativeChain.
    function setNativeChainAndToken(address _newNativeToken, uint256 _newNativeChain) external onlyOwner {
        require(_newNativeToken != address(0), 'zero addr');
        lqdrNativeToken = _newNativeToken;
        NATIVECHAIN = _newNativeChain;
    }


    /// @dev Returns the total supply of WERC10 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balanceOf[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    /// @dev Sets `value` as allowance of `spender` account over caller account's WERC10 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's WERC10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        
        return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's WERC10 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// WERC10 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "WERC10: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                target,
                spender,
                value,
                nonces[target]++,
                deadline));

        require(verifyEIP712(target, hashStruct, v, r, s) || verifyPersonalSign(target, hashStruct, v, r, s));

        // _approve(owner, spender, value);
        allowance[target][spender] = value;
        emit Approval(target, spender, value);
    }

    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool) {
        require(block.timestamp <= deadline, "WERC10: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                target,
                to,
                value,
                nonces[target]++,
                deadline));

        require(verifyEIP712(target, hashStruct, v, r, s) || verifyPersonalSign(target, hashStruct, v, r, s));

        require(to != address(0) || to != address(this));
        
        uint256 balance = balanceOf[target];
        require(balance >= value, "WERC10: transfer amount exceeds balance");

        balanceOf[target] = balance - value;
        balanceOf[to] += value;
        emit Transfer(target, to, value);
        
        return true;
    }
    
    function verifyEIP712(address target, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }
    
    function verifyPersonalSign(address target, bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }
    
    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /// @dev Moves `value` WERC10 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WERC10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WERC10 token.
    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0) || to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "WERC10: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        
        return true;
    }

    /// @dev Moves `value` WERC10 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WERC10 token in favor of caller.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WERC10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WERC10 token, unless `from` and caller are the same account.
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(to != address(0) || to != address(this));
        if (from != msg.sender) {
            // _decreaseAllowance(from, msg.sender, value);
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WERC10: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }
        
        uint256 balance = balanceOf[from];
        require(balance >= value, "WERC10: transfer amount exceeds balance");

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        
        return true;
    }

    /// @dev Moves `value` WERC10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WERC10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WERC10 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external override returns (bool) {
        require(to != address(0) || to != address(this));
        
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "WERC10: transfer amount exceeds balance");

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }
}