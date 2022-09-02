// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./PausableControl.sol";

import "./AdminControl.sol";

abstract contract PausableControlWithAdmin is PausableControl, AdminControl {
    constructor(address _admin) AdminControl(_admin) {
    }

    function pause(bytes32 role) external onlyAdmin {
        _pause(role);
    }

    function unpause(bytes32 role) external onlyAdmin {
        _unpause(role);
    }
}