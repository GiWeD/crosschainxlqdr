// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/*
    This vault holds the crosschained LQDRs tokens.
    Only AnyswapClient or Owner can deposit/withdraw LQDR.
    When bridge from FTM --> chain B, LQDR are sent here.
    This is done because we cannot mint/burn LQDR on FTM chain. Only 0x74 (original immutable chef) can.
*/


contract LQDRVault is OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public lqdr ;

    mapping(address => bool) public isAuth;

    event Deposit(uint256 amount, address user);
    event Withdraw(uint256 amount, address user);

    modifier onlyAuth() {
        require(msg.sender == owner() || isAuth[msg.sender], 'not auth');
        _;
    }

    constructor() {}

     function initialize() public initializer {
        __Ownable_init();    
        lqdr = address(0xb456D55463A84C7A602593D55DB5a808bF46aAc9); //ftm testnet 0xb456D55463A84C7A602593D55DB5a808bF46aAc9, mainnet: 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9
    }


    function deposit(address _from, uint256 amount) external onlyAuth returns(bool) {
        require(amount > 0, 'check in');
        require(_from != address(0), 'zero addr');
        IERC20Upgradeable(lqdr).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(amount, _from);
        return true;
    }

    function withdraw(address _to,uint256 amount) external onlyAuth  returns(bool) {
        require(amount > 0, 'check in');
        require(_to != address(0), 'addr 0');
        IERC20Upgradeable(lqdr).safeTransfer(_to, amount);
        emit Withdraw(amount, _to);
        return true;
    }


    function addAuth(address[] calldata _addresses) external onlyOwner {

        require(_addresses.length > 0, 'no input');
        uint256 i = 0;
        for(i; i < _addresses.length; i++){
            require(_addresses[i] != address(0), 'addr 0');
            isAuth[_addresses[i]] = true;
        }
        
    }

    function removeAuth(address[] calldata _addresses) external onlyOwner {

        require(_addresses.length > 0, 'no input');
        uint256 i = 0;
        for(i; i < _addresses.length; i++){
            require(_addresses[i] != address(0), 'addr 0');
            isAuth[_addresses[i]] = false;
        }
        
    }






}