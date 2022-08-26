// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/ILockedToken.sol";


contract Controller  {

    address public constant xlqdr = address(0x3Ae658656d1C526144db371FaEf2Fff7170654eE);


    constructor() public {}




    /*
        @Notice update xLQDR vote power on a chain given the Chain ID. On CHAINID there will be a xLQDR.vy clone with the same decay time
        
        @param      chainID     unsigned int for the chainID, could be lowered to 16-32bit
        @return     bool        return a boolean to know if the lock worked. Wait for Layer 0 / CCIP confirmation      
    */ 

    function updateXLQDR(uint256 chainId) external returns(bool) {


        
        // save user address
        address user = msg.sender;

        // check he has something locked and lock is still active
        require(ILockedToken(xlqdr).balanceOf(user) > 0, 'no lock amount');
        require(ILockedToken(xlqdr).locked__end(user) > block.timestamp, 'lock end');


        // get info:
        // - amount:        locked amount
        // - endTime:       lock end
        // - startTime:     lock start

        int128 amount;
        uint256 end;   

        (amount, end) =  ILockedToken(xlqdr).locked(user);     

        


        return true;



    }




}