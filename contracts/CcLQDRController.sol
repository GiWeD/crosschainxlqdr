// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./interfaces/ILockedToken.sol";
import "./interfaces/ILqdr.sol";
import "./interfaces/ICcLQDRController.sol";

import "./LayerZero/ILayerZeroReceiver.sol";
import "./LayerZero/ILayerZeroEndpoint.sol";

contract CcLQDRController is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC20Upgradeable, ILayerZeroReceiver  {


    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    ILayerZeroEndpoint public endpoint; 

    uint256 public layerZeroChainId;
    mapping(uint256=>uint256) public layerZeroToChainIds;

    bool public isLqdrNativeChain;                  // we need to know if we are in ftm

    address public lqdr;                            // lqdr address on the given layerZeroChainId (ftm 0x10b...)

    mapping(uint256=>bytes) public controller;      // map controller for each layerZeroChainId
    mapping(address=>bool) public isAllowed;        // allow address to operate
    mapping(uint256=>bool) public isLayerZeroChainId; // map any layerZeroChainId

    
    constructor() public {}
    
    function initialize(address _lqdr, ILayerZeroEndpoint _endpoint, uint256 _layerZeroChainId, bool _isNative) public initializer {

        __Ownable_init();
        endpoint = _endpoint;
        isLqdrNativeChain = _isNative;   //true if FTM, else false
        lqdr = _lqdr;
        layerZeroChainId = _layerZeroChainId;
        isLayerZeroChainId[_layerZeroChainId];
    
    }

    modifier onlyAllowed {
        require(isAllowed[msg.sender], 'not allowed');
        _;
    }



    function bridgeTo(uint256 _dstLayerZeroChainId, uint256 _amount, address _to, uint256 _extraGas) external payable nonReentrant {

        require(isLayerZeroChainId[_dstLayerZeroChainId], 'chain not supported');
        require(_dstLayerZeroChainId != layerZeroChainId, 'same chain');
        require(_amount > 0, 'amount');


        // if we are not on FTM then burn LQDR, else just keep in the contract. 
        // LQDR(FTM).totalSupply() === sum_i( LQDR(layerZeroChainId[i]).totalSupply() )
        if(!isLqdrNativeChain){
            ILqdr(lqdr).burn(msg.sender, _amount);
        } else {
            _deposit(_amount, msg.sender);
        }

        bytes memory _dstContractAddress = (controller[_dstLayerZeroChainId]);
        require(_dstContractAddress.length > 0, 'Unsupported dst addr');

        bytes memory payload = abi.encode(_amount, _to);
        bytes memory adapterParams = abi.encodePacked(uint16(1), _extraGas);

        endpoint.send{value:msg.value}(
            uint16(_dstLayerZeroChainId),     // destination LayerZero layerZeroChainId
            _dstContractAddress,            // send to this address on the destination          
            payload,                        // bytes payload
            payable(msg.sender),            // refund address
            address(0x0),                   // future parameter
            adapterParams                   // adapterParams (see "Advanced Features")
        );

    }


    function lzReceive(uint16 _srcLayerZeroChainId,bytes calldata _srcAddress,uint64 _nonce,bytes calldata _payload) override external  {

        // only L0 Endpoint
        require(msg.sender == address(endpoint), 'not endpoint');
        // check source address is allowed
        require(_srcAddress.length == controller[_srcLayerZeroChainId].length, 'wrong srcAddr');
        require(keccak256(_srcAddress) == keccak256(controller[_srcLayerZeroChainId]), 'wrong srcAddr' );

        // decode payload
        uint256 _amount;
        address _to;
        (_amount, _to) = abi.decode(_payload, (uint256, address));
        mintLqdr(_amount, _to);
    }
       

    function _deposit(uint256 _amount, address _from) private {
        IERC20Upgradeable(lqdr).safeTransferFrom(_from, address(this), _amount);
    }

    function _withdraw(uint256 _amount, address _to) private {
        IERC20Upgradeable(lqdr).safeTransfer(_to, _amount);
    }

    function mintLqdr(uint256 _amount, address _to) public onlyAllowed {

         if(!isLqdrNativeChain){
            ILqdr(lqdr).mint(msg.sender, _amount);
        } else {
            _withdraw(_amount, _to);
        }

    }


    /*
        SETTERS
    */

    function setEndpoint(ILayerZeroEndpoint _endpoint) external onlyOwner {
        require(_endpoint != endpoint, 'already set');
        endpoint = _endpoint;
    }

    function setControllerAddress(uint256 _toLayerZeroChainId, bytes calldata _controller) external onlyOwner {
        controller[_toLayerZeroChainId] = _controller;
    }

    function removeControllerAddress(uint256 _toLayerZeroChainId) external onlyOwner {
        controller[_toLayerZeroChainId] = bytes("0");
    }

    function setCurrentLayerZeroChainId(uint256 _layerZeroChainId) external onlyOwner {
        require(_layerZeroChainId != layerZeroChainId, 'already set');
        layerZeroChainId = _layerZeroChainId;
    }

    function addLayerZeroChainId(uint256 _layerZeroChainId, uint256 chainId) external onlyOwner {
        layerZeroToChainIds[_layerZeroChainId] = chainId;
        isLayerZeroChainId[_layerZeroChainId] = true;
    }

    function removeLayerZeroChainId(uint256 _layerZeroChainId) external onlyOwner {
        layerZeroToChainIds[_layerZeroChainId] = 0;
        isLayerZeroChainId[_layerZeroChainId] = false;
    }


  



}