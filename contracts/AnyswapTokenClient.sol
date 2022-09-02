// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "./AnycallClientBase.sol";

interface IAnyswapToken {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    function changeOwner(address newOwner) external returns (bool);
}

interface IAnycallExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}



/// three level architecture
/// top level is the `AnycallClient` which the users interact with (through UI or tools)
/// middle level is `AnyswapToken` which works as handlers and vaults for tokens
/// bottom level is the `AnycallProxy` which complete the cross-chain interaction



contract AnyswapTokenClient is AnycallClientBase {
    using SafeERC20 for IERC20;

    // pausable control roles
    bytes32 public constant PAUSE_SWAPOUT_ROLE = keccak256("PAUSE_SWAPOUT_ROLE");
    bytes32 public constant PAUSE_SWAPIN_ROLE = keccak256("PAUSE_SWAPIN_ROLE");
    bytes32 public constant PAUSE_FALLBACK_ROLE = keccak256("PAUSE_FALLBACK_ROLE");


    // associated tokens on each chain
    mapping(address => mapping(uint256 => address)) public tokenPeers;

    event LogSwapout(address indexed token, address indexed sender, address indexed receiver,uint256 amount, uint256 toChainId);
    event LogSwapin(address indexed token, address indexed sender, address indexed receiver,uint256 amount, uint256 fromChainId);
    event LogSwapoutFail(address indexed token, address indexed sender, address indexed receiver,uint256 amount, uint256 toChainId);


    constructor(address _admin,address _callProxy) AnycallClientBase(_admin, _callProxy) {    }

    function setTokenPeers(address srcToken,uint256[] calldata chainIds,address[] calldata dstTokens) external onlyAdmin {
        require(chainIds.length == dstTokens.length);
        for (uint256 i = 0; i < chainIds.length; i++) {
            tokenPeers[srcToken][chainIds[i]] = dstTokens[i];
        }
    }

    /// @dev Call by the user to submit a request for a cross chain interaction
    function swapout(address token,uint256 amount,address receiver,uint256 toChainId,uint256 flags) external payable whenNotPaused(PAUSE_SWAPOUT_ROLE) {
        address clientPeer = clientPeers[toChainId];
        require(clientPeer != address(0), "AnycallClient: no dest client");

        address dstToken = tokenPeers[token][toChainId];
        require(dstToken != address(0), "AnycallClient: no dest token");

        uint256 oldCoinBalance;
        if (msg.value > 0) {
            oldCoinBalance = address(this).balance - msg.value;
        }

        address _underlying = _getUnderlying(token);

        if (_underlying != address(0)) {
            uint256 old_balance = IERC20(_underlying).balanceOf(token);

            IERC20(_underlying).safeTransferFrom(msg.sender, token, amount);

            uint256 new_balance = IERC20(_underlying).balanceOf(token);

            // update amount to real balance increasement (some token may deduct fees)
            amount = new_balance > old_balance ? new_balance - old_balance : 0;
        } else {
            assert(IAnyswapToken(token).burn(msg.sender, amount));
        }

        bytes memory data = abi.encodeWithSelector(
            this.anyExecute.selector,
            token,
            dstToken,
            amount,
            msg.sender,
            receiver,
            toChainId
        );
        IAnycallV6Proxy(callProxy).anyCall{value: msg.value}(
            clientPeer,
            data,
            address(this),
            toChainId,
            flags
        );

        if (msg.value > 0) {
            uint256 newCoinBalance = address(this).balance;
            if (newCoinBalance > oldCoinBalance) {
                // return remaining fees
                (bool success,) = msg.sender.call{value: newCoinBalance - oldCoinBalance}("");
                require(success);
            }
        }

        emit LogSwapout(token, msg.sender, receiver, amount, toChainId);
    }

    /// @notice Call by `AnycallProxy` to execute a cross chain interaction on the destination chain
    function anyExecute(bytes calldata data)
        external
        override
        onlyExecutor
        whenNotPaused(PAUSE_SWAPIN_ROLE)
        returns (bool success, bytes memory result)
    {
        
        bytes4 selector = bytes4(data[:4]);
        if (selector == this.anyExecute.selector) {
            (address srcToken,address dstToken,uint256 amount,address sender,address receiver,/*uint256 toChainId*/) = abi.decode(data[4:],(address, address, uint256, address, address, uint256));

            address executor = IAnycallV6Proxy(callProxy).executor();
            (address from, uint256 fromChainId,) = IAnycallExecutor(executor).context();
            require(clientPeers[fromChainId] == from, "AnycallClient: wrong context");
            require(tokenPeers[dstToken][fromChainId] == srcToken, "AnycallClient: mismatch source token");

            address _underlying = _getUnderlying(dstToken);

            if (_underlying != address(0) && (IERC20(dstToken).balanceOf(address(this)) >= amount)) {
                IERC20(dstToken).safeTransferFrom(address(this), receiver, amount);
            } else {
                assert(IAnyswapToken(dstToken).mint(receiver, amount));
            }
            emit LogSwapin(dstToken, sender, receiver, amount, fromChainId);
        } else if (selector == 0xa35fe8bf) { // bytes4(keccak256('anyFallback(address,bytes)'))
            (address _to, bytes memory _data) = abi.decode(data[4:], (address, bytes));
            anyFallback(_to, _data);
        } else {
            return (false, "unknown selector");
        }
        return (true, "");
    }

    /// @dev Call back by `AnycallProxy` on the originating chain if the cross chain interaction fails
    function anyFallback(address to, bytes memory data)
        internal
        whenNotPaused(PAUSE_FALLBACK_ROLE)
    {
        address executor = IAnycallV6Proxy(callProxy).executor();
        (address _from,,) = IAnycallExecutor(executor).context();
        require(_from == address(this), "AnycallClient: wrong context");

        (
            bytes4 selector,
            address srcToken,
            address dstToken,
            uint256 amount,
            address from,
            address receiver,
            uint256 toChainId
        ) = abi.decode(
            data,
            (bytes4, address, address, uint256, address, address, uint256)
        );

        require(selector == this.anyExecute.selector, "AnycallClient: wrong fallback data");
        require(clientPeers[toChainId] == to, "AnycallClient: mismatch dest client");
        require(tokenPeers[srcToken][toChainId] == dstToken, "AnycallClient: mismatch dest token");

        address _underlying = _getUnderlying(srcToken);

        if (_underlying != address(0) && (IERC20(srcToken).balanceOf(address(this)) >= amount)) {
            IERC20(_underlying).safeTransferFrom(address(this), from, amount);
        } else {
            assert(IAnyswapToken(srcToken).mint(from, amount));
        }

        emit LogSwapoutFail(srcToken, from, receiver, amount, toChainId);
    }

    function _getUnderlying(address token) internal returns (address) {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(0x6f307dc3));
        if (success && returndata.length > 0) {
            (address _underlying) = abi.decode(returndata, (address));
            return _underlying;
        }
        return address(0);
    }

    /* Used to move minting/burning rights */
    function changeTokenOwner(address token, address newOwner) external onlyAdmin {
        require(newOwner != address(0), 'newOwner addr0');
        IAnyswapToken(token).changeOwner(newOwner);

    }



}