

const { expect } = require("chai");
const { ethers, web3 } = require("hardhat");
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert,
    balance, // Assertions for transactions that should fail
  } = require('@openzeppelin/test-helpers');


const { erc20Abi } = require("../scripts/Abi.js")

const ether = require("@openzeppelin/test-helpers/src/ether.js");
const { LogDescription } = require("ethers/lib/utils");


const geistStaking = ethers.utils.getAddress("0x49c93a95dbcc9A6A4D8f77E59c038ce5020e82f8")
const geistStakingAbi = [{"inputs":[{"internalType":"address","name":"_stakingToken","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Recovered","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":true,"internalType":"address","name":"rewardsToken","type":"address"},{"indexed":false,"internalType":"uint256","name":"reward","type":"uint256"}],"name":"RewardPaid","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"token","type":"address"},{"indexed":false,"internalType":"uint256","name":"newDuration","type":"uint256"}],"name":"RewardsDurationUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Staked","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Withdrawn","type":"event"},{"inputs":[{"internalType":"address","name":"_rewardsToken","type":"address"}],"name":"addReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"claimableRewards","outputs":[{"components":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"internalType":"struct MultiFeeDistribution.RewardData[]","name":"rewards","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"earnedBalances","outputs":[{"internalType":"uint256","name":"total","type":"uint256"},{"components":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"unlockTime","type":"uint256"}],"internalType":"struct MultiFeeDistribution.LockedBalance[]","name":"earningsData","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"exit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"getReward","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardsToken","type":"address"}],"name":"getRewardForDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardsToken","type":"address"}],"name":"lastTimeRewardApplicable","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lockDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"lockedBalances","outputs":[{"internalType":"uint256","name":"total","type":"uint256"},{"internalType":"uint256","name":"unlockable","type":"uint256"},{"internalType":"uint256","name":"locked","type":"uint256"},{"components":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"unlockTime","type":"uint256"}],"internalType":"struct MultiFeeDistribution.LockedBalance[]","name":"lockData","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lockedSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bool","name":"withPenalty","type":"bool"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"minters","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"mintersAreSet","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"tokenAddress","type":"address"},{"internalType":"uint256","name":"tokenAmount","type":"uint256"}],"name":"recoverERC20","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"rewardData","outputs":[{"internalType":"uint256","name":"periodFinish","type":"uint256"},{"internalType":"uint256","name":"rewardRate","type":"uint256"},{"internalType":"uint256","name":"lastUpdateTime","type":"uint256"},{"internalType":"uint256","name":"rewardPerTokenStored","type":"uint256"},{"internalType":"uint256","name":"balance","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_rewardsToken","type":"address"}],"name":"rewardPerToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"rewardTokens","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"rewards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rewardsDuration","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_minters","type":"address[]"}],"name":"setMinters","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bool","name":"lock","type":"bool"}],"name":"stake","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"stakingToken","outputs":[{"internalType":"contract IMintableToken","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"totalBalance","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"unlockedBalance","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"userRewardPerTokenPaid","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawExpiredLocks","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"withdrawableBalance","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"uint256","name":"penaltyAmount","type":"uint256"}],"stateMutability":"view","type":"function"}]

const fakeLP = ethers.utils.getAddress("0x30A92a4EEca857445F41E4Bb836e64D66920F1C0")
const addrZero = ethers.utils.getAddress("0x0000000000000000000000000000000000000000")
const geist = ethers.utils.getAddress("0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d")
const gUSDC = ethers.utils.getAddress("0xe578c856933d8e1082740bf7661e379aa2a30b26")
const gFTM = ethers.utils.getAddress("0x39b3bd37208cbade74d0fcbdbb12d606295b430a")
const USDC = ethers.utils.getAddress("0x04068da6c83afcfa0e13ba15a6696662335d5b75")
const gftmGateway = ethers.utils.getAddress("0x47102245FEa0F8D35a6b28E54505e9FfD83d0704")
const spookyrouter = ethers.utils.getAddress("0xF491e7B69E4244ad4002BC14e878a34207E38c29")


const tokenRewards = [
    gFTM,
    gUSDC,
    ethers.utils.getAddress("0x940f41f0ec9ba1a34cf001cc03347ac092f5f6b5"),
    ethers.utils.getAddress("0x07e6332dd090d287d3489245038daf987955dcfb"),
    ethers.utils.getAddress("0x25c130b2624cf12a4ea30143ef50c5d68cefa22f"),
    ethers.utils.getAddress("0x38aca5484b8603373acc6961ecd57a6a594510a3"),    
    ethers.utils.getAddress("0x690754a168b022331caa2467207c61919b3f8a98"),    
    ethers.utils.getAddress("0xc664fc7b8487a3e10824cda768c1d239f2403bbe"),
    geist
]

const underlyingToken = [

    ethers.utils.getAddress("0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83"),
    USDC,
    ethers.utils.getAddress("0x049d68029688eAbF473097a2fC38ef61633A3C7A"),
    ethers.utils.getAddress("0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E"),
    ethers.utils.getAddress("0x74b23882a30290451A17c44f4F05243b6b58C76d"),
    ethers.utils.getAddress("0x321162Cd933E2Be498Cd2267a90534A804051b11"),    
    ethers.utils.getAddress("0x1E4F97b9f9F913c46F1632781732927B9019C68b"),    
    ethers.utils.getAddress("0x82f0B8B456c1A451378467398982d4834b6829c1"),
    geist
]

describe("LiGeist TEST UNIT", function () {
   
    beforeEach(async () => {
        
        await ethers.provider.send('evm_increaseTime', [1]);
        await ethers.provider.send('evm_mine');
   
    });
    
    it("Prepare contracts", async function () {
        
        accounts = await ethers.getSigners();
        owner = accounts[0]

        geistStakingContract = new ethers.Contract(geistStaking, geistStakingAbi, owner   )  
        
        geistContract = new ethers.Contract(geist, erc20Abi, owner   )  
        
        gUSDCContract = new ethers.Contract(gUSDC, erc20Abi, owner   )  


    });


    it("Deploy Contracts", async function () {

        // deploy
        data = await ethers.getContractFactory("LiGeist");
        ligeistContract = await data.deploy();
        txDeployed = await ligeistContract.deployed();
        expect(await ligeistContract.owner()).to.equal(owner.address)


        // upgradeable contract
        data = await ethers.getContractFactory("LiGEISTChef");
        ligeistChefContract = await upgrades.deployProxy(data,[gUSDC], {initializer: 'initialize'});
        txDeployed = await ligeistChefContract.deployed();
        expect(await ligeistChefContract.owner()).to.equal(owner.address)

    });
});