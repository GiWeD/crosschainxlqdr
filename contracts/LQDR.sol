// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LQDR is ERC20('Liquid Driver', 'LQDR'), Ownable {


    mapping(address => bool) public isAllowed;

    modifier isControllerOrOwner {
        require(isAllowed[msg.sender] || msg.sender == owner(), 'not allowed to mint/burn');
        _;
    }
    
    constructor() public {}



    function mint(address _to, uint256 _amount) public isControllerOrOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public isControllerOrOwner {
        _burn(_from, _amount);
    }



    function addController(address _controller) external onlyOwner {
        require(!isAllowed[_controller], 'already in');

        isAllowed[_controller] = true;
    }

    function removeController(address _controller) external onlyOwner {
        require(isAllowed[_controller], 'already in');

        isAllowed[_controller] = false;
    }



}