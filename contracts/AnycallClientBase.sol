
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./access/PausableControlWithAdmin.sol";


interface IAnycallV6Proxy {
    function executor() external view returns (address);

    function anyCall(address _to,bytes calldata _data,address _fallback,uint256 _toChainID,uint256 _flags) external payable;
}


interface IApp {
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);
}



abstract contract AnycallClientBase is IApp, PausableControlWithAdmin {
    address public callProxy;
    address public anycallExecutor;
    // associated client app on each chain
    mapping(uint256 => address) public clientPeers; // key is chainId

    modifier onlyExecutor() {
        require(msg.sender == anycallExecutor, "AnycallClient: not authorized");
        _;
    }

    constructor(address _admin, address _callProxy) PausableControlWithAdmin(_admin) {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        anycallExecutor = IAnycallV6Proxy(callProxy).executor();
    }

    receive() external payable {
        require(msg.sender == callProxy, "AnycallClient: receive from forbidden sender");
    }

    function setCallProxy(address _callProxy) external onlyAdmin {
        require(_callProxy != address(0));
        callProxy = _callProxy;
        anycallExecutor = IAnycallV6Proxy(callProxy).executor();

    }

    function setClientPeers(
        uint256[] calldata _chainIds,
        address[] calldata _peers
    ) external onlyAdmin {
        require(_chainIds.length == _peers.length);
        for (uint256 i = 0; i < _chainIds.length; i++) {
            clientPeers[_chainIds[i]] = _peers[i];
        }
    }
}