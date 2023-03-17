// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/Math.sol";

interface IMirroredVotingEscrow {

    function balanceOf(address) external view returns(uint);
    function totalSupply() external view returns(uint);
}


contract Rewarder is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public DURATION = 7 * 86400;

    address[] public rewardTokens;
    address public VE;

    // reward token mappings
    mapping(address => bool) public isRewardToken;
    mapping(address => uint) public tokenRewardRate;
    mapping(address => uint) public tokenPeriodFinish;
    mapping(address => uint) public tokenLastUpdateTime;
    mapping(address => uint) public tokenRewardPerTokenStored;


    // user mappings
    // user -> token -> amount
    mapping(address => mapping(address=> uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public userRewards;



    event Harvest(address indexed user, uint256 reward);

    constructor(address _ve) {
        VE = _ve;   // mirror voting escrow
    }


    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    function addRewardTokens(address[] memory tokens) external onlyOwner {
        uint i;
        for (i = 0; i < tokens.length; i++) {
            if(isRewardToken[tokens[i]] == false){
                rewardTokens.push((tokens[i]));
                isRewardToken[tokens[i]] = true;
            }
        }
    }

    function removeRewardTokens(address[] memory tokens) external onlyOwner {
        uint i = 0;
        for(i; i < _rewardTokensLength(); i++){
            if(address(rewardTokens[i]) == tokens[i] && isRewardToken[tokens[i]]){
                isRewardToken[tokens[i]] = false;
                rewardTokens[i] = rewardTokens[_rewardTokensLength() - 1];
                rewardTokens.pop();
            }
        }
    }

    /// @notice set a new duration for the distribution. Min 1 DAY. 
    /// @dev    after update duration, checkpoint tokens data
    function setNewDuration(uint period) external onlyOwner {
        require(period >= 86400 && period != DURATION);
        DURATION = period;
        _forceCheckPointAll();
    }

    ///@notice Force checkPoint token
    function forceCheckPointAll() external onlyOwner {
        _forceCheckPointAll();
    }

    function recoverAllERC20(address tokenAddress) external onlyOwner {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).safeTransfer(owner(), balance);
    }

    function recoverAmountERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    VIEW FUNCTIONS
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    ///@notice total supply held
    function totalSupply() public view returns (uint256) {
        return IMirroredVotingEscrow(VE).totalSupply();
    }

    ///@notice balance of a user
    function balanceOf(address account) external view returns (uint256) {
        return IMirroredVotingEscrow(VE).balanceOf(account);
    }

    ///@notice last time reward
    function lastTimeRewardApplicable(address token) public view returns (uint256) {
        return Math.min(block.timestamp, _periodFinish(token));
    }

    ///@notice  reward for a single token
    function rewardPerToken(address token) public view returns (uint256) {
        uint _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            return tokenRewardPerTokenStored[token];
        } else {
            uint _rewardRate = tokenRewardRate[token];
            uint lastT = lastTimeRewardApplicable(token);
            uint lastUT = tokenLastUpdateTime[token];
            return tokenRewardPerTokenStored[token].add( lastT.sub(lastUT).mul(_rewardRate).mul(1e18).div(_totalSupply));
        }
    }

    ///@notice see earned rewards for user
    ///@return _rewards amount to claim respect to rewardTokens.
    function earned(address account) public view returns (uint256[] memory) {

        uint _balance = IMirroredVotingEscrow(VE).balanceOf(account);

        uint i = 0;
        address _token;

        uint256[] memory _rewards = new uint256[](_rewardTokensLength());

        for(i; i < rewardTokens.length; i++){
            _token = rewardTokens[i];
            _rewards[i] = _balance.mul(rewardPerToken(_token).sub(userRewardPerTokenPaid[account][_token])).div(1e18).add(userRewards[account][_token]);
        }
        
        return _rewards;
    }

    ///@notice get total reward for the duration
    function rewardForDuration(address token) public view returns (uint256) {
        return tokenRewardRate[token].mul(DURATION);
    }

    function _periodFinish(address _token) public view returns (uint256) {
        return tokenPeriodFinish[_token];
    }

    function _rewardTokens() public view returns(address[] memory) {
        return rewardTokens;
    }

    function _rewardTokensLength() public view returns(uint) {
        return rewardTokens.length;
    }



    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    USER INTERACTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */


    ///@notice User claim function
    function claim() public nonReentrant  {
        address _user = msg.sender;
        _updateReward();
        
        uint256[] memory _rewards = new uint256[](_rewardTokensLength());
        _rewards = earned(_user);

        uint i = 0;
        for(i = 0; i < _rewardTokensLength(); i++){
            uint256 reward = _rewards[i];
            userRewardPerTokenPaid[_user][rewardTokens[i]] = tokenRewardPerTokenStored[rewardTokens[i]];
            if (reward > 0) {
                userRewards[_user][rewardTokens[i]] = 0;
                IERC20(rewardTokens[i]).safeTransfer(_user, reward);
                emit Harvest(_user, reward);
            }
        }
    }
    

    ///@notice update reward info 
    function _updateReward() internal {
        uint i = 0;
        for(i; i < _rewardTokensLength(); i++){
            tokenRewardPerTokenStored[rewardTokens[i]] = rewardPerToken(rewardTokens[i]);
            tokenLastUpdateTime[rewardTokens[i]] = lastTimeRewardApplicable(rewardTokens[i]);
        }
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    DISTRIBUTION
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */


    /// @dev Receive rewards from distribution
    function checkpoint(address[] memory _tokens) external nonReentrant {
        uint i = 0;

        for(i; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(isRewardToken[token], 'token not allowed');

            uint reward = IERC20(token).balanceOf(address(this));
            uint periodFinish = tokenPeriodFinish[token];

            if (block.timestamp >= periodFinish) {
                tokenRewardRate[token] = reward.div(DURATION);
                tokenPeriodFinish[token] = block.timestamp.add(DURATION);

            } else {
                // if we are here then update only leftover
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul( tokenRewardRate[token]);
                tokenRewardRate[token] = (leftover).div(DURATION);
            }

            uint256 balance = IERC20(token).balanceOf(address(this));
            require(tokenRewardRate[token] <= balance.div(DURATION), "Provided reward too high");

            tokenLastUpdateTime[token] = block.timestamp;
        }
    }

    function checkpointAll() public nonReentrant {
        uint i = 0;
        for(i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            require(isRewardToken[token], 'token not allowed');
            uint reward = IERC20(token).balanceOf(address(this));
            uint periodFinish = tokenPeriodFinish[token];

            if (block.timestamp >= periodFinish) {
                tokenRewardRate[token] = reward.div(DURATION);
                tokenPeriodFinish[token] = block.timestamp.add(DURATION);
            } else {
                // if we are here then update only leftover
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul( tokenRewardRate[token]);
                tokenRewardRate[token] = (leftover).div(DURATION);
            }
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(tokenRewardRate[token] <= balance.div(DURATION), "Provided reward too high");
            tokenLastUpdateTime[token] = block.timestamp;
        }
    }

    function _forceCheckPointAll() internal nonReentrant {
        uint i = 0;
        for(i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            require(isRewardToken[token], 'token not allowed');
            uint reward = IERC20(token).balanceOf(address(this));
            tokenRewardRate[token] = reward.div(DURATION);
            tokenPeriodFinish[token] = block.timestamp.add(DURATION);
            uint256 balance = IERC20(token).balanceOf(address(this));
            require(tokenRewardRate[token] <= balance.div(DURATION), "Provided reward too high");
            tokenLastUpdateTime[token] = block.timestamp;
        }
    }


}
