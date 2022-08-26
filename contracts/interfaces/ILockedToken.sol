// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ILockedToken {


    function balanceOf(address user) external view returns(uint256);
    function balanceOf(address user, uint256 timestamp) external view returns(uint256);
    function balanceOfAt(address user, uint256 _block) external view returns(uint256);
        
    function locked__end(address user) external view returns(uint256);

    function locked(address user) external view returns(int128 amount, uint256 end);




}