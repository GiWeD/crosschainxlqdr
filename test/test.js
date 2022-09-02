

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
jsonabi2  = [{"inputs":[{"internalType":"address","name":"_admin","type":"address"},{"internalType":"address","name":"_callProxy","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_old","type":"address"},{"indexed":true,"internalType":"address","name":"_new","type":"address"}],"name":"ApplyAdmin","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_old","type":"address"},{"indexed":true,"internalType":"address","name":"_new","type":"address"}],"name":"ChangeAdmin","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"fromChainId","type":"uint256"}],"name":"LogSwapin","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"toChainId","type":"uint256"}],"name":"LogSwapout","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"token","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"},{"indexed":true,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"toChainId","type":"uint256"}],"name":"LogSwapoutFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"Unpaused","type":"event"},{"inputs":[],"name":"PAUSE_ALL_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PAUSE_FALLBACK_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PAUSE_SWAPIN_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PAUSE_SWAPOUT_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"admin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"data","type":"bytes"}],"name":"anyExecute","outputs":[{"internalType":"bool","name":"success","type":"bool"},{"internalType":"bytes","name":"result","type":"bytes"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"anycallExecutor","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"applyAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"callProxy","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_admin","type":"address"}],"name":"changeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"address","name":"newOwner","type":"address"}],"name":"changeTokenOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"clientPeers","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingAdmin","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_callProxy","type":"address"}],"name":"setCallProxy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"_chainIds","type":"uint256[]"},{"internalType":"address[]","name":"_peers","type":"address[]"}],"name":"setClientPeers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"srcToken","type":"address"},{"internalType":"uint256[]","name":"chainIds","type":"uint256[]"},{"internalType":"address[]","name":"dstTokens","type":"address[]"}],"name":"setTokenPeers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"toChainId","type":"uint256"},{"internalType":"uint256","name":"flags","type":"uint256"}],"name":"swapout","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"tokenPeers","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
abi3 = [{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"address","name":"user","type":"address"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint8","name":"version","type":"uint8"}],"name":"Initialized","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"address","name":"user","type":"address"}],"name":"Withdraw","type":"event"},{"inputs":[{"internalType":"address[]","name":"_addresses","type":"address[]"}],"name":"addAuth","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"deposit","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"isAuth","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"lqdr","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_addresses","type":"address[]"}],"name":"removeAuth","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}]


describe("TEST UNIT", function () {
   
    beforeEach(async () => {
        
        await ethers.provider.send('evm_increaseTime', [1]);
        await ethers.provider.send('evm_mine');
   
    });
    
    it("", async function () {
        accounts = await ethers.getSigners();
        owner = accounts[0]

        vaultAddress = ethers.utils.getAddress("0xbDBF29a038095d7270249D14D5f0BAe4E38f7B8A")
        proxyAddr =  ethers.utils.getAddress("0x852c882963da259168fa7bef2f737c988c3cf5ac")

        lqdrProxyFactory = await ethers.getContractFactory("LQDR");
        lqdrProxyFactoryContract = await lqdrProxyFactory.deploy( "LiquidDriver", "LQDR", 18, owner.address, vaultAddress);
        txDeployed = await lqdrProxyFactoryContract.deployed();
        await lqdrProxyFactoryContract.allowMinter(proxyAddr)
        console.log('Contract LQDR deployed to:', lqdrProxyFactoryContract.address);
        console.log('Owner: ', (await lqdrProxyFactoryContract.owner()).toString())
        console.log('lqdrNativeToken: ', (await lqdrProxyFactoryContract.lqdrNativeToken()).toString())
        console.log('chainId: ', (await lqdrProxyFactoryContract.chainId()).toString())


        userToTest = ethers.utils.getAddress("0xd1ad51d0DBcec5e50705C505fd2c2c7908722840");
       
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [userToTest],
        });
        signer = await ethers.getSigner(userToTest)
        
        anyCallPRoxy = new ethers.Contract( proxyAddr, jsonabi2, owner)
        console.log ( "ad proxy:", (await anyCallPRoxy.admin()).toString() );

        vault = new ethers.Contract( vaultAddress,abi3 , owner)
        console.log ("ad vault:", (await vault.owner()).toString() );
        
        console.log('-------- Settings ----------')
        await anyCallPRoxy.connect(signer).setTokenPeers(lqdrProxyFactoryContract.address, [4], [ethers.utils.getAddress("0x38D010Dd73Cc7C1A087eC68d689Ec4e43F0aF6e7")])
        await vault.connect(signer).addAuth([lqdrProxyFactoryContract.address])


        console.log('-------- Approvals ----------')
        lqdrOriginalContract = new ethers.Contract(ethers.utils.getAddress("0xb456D55463A84C7A602593D55DB5a808bF46aAc9"), erc20Abi, owner)
        console.log( (await lqdrOriginalContract.symbol()).toString() );
        tx = await lqdrOriginalContract.connect(signer).approve(vaultAddress, ethers.utils.parseEther("1000"))
        await tx.wait()
        
        tx = await lqdrOriginalContract.connect(signer).approve(lqdrProxyFactoryContract.address, ethers.utils.parseEther("1000"))
        await tx.wait()

        console.log( (await lqdrOriginalContract.balanceOf(userToTest)).toString() );
        tx = await lqdrOriginalContract.connect(signer).approve(proxyAddr, ethers.utils.parseEther("1000"))
        await tx.wait()
        
        console.log('-------- swapping out ----------')
        token = lqdrProxyFactoryContract.address
        amount = ethers.utils.parseEther("1")
        receiver = userToTest
        toChain = 4
        await anyCallPRoxy.connect(signer).swapout(token, amount, receiver, toChain, 2, {value: 15, gasLimit: 3000000 })


        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: [userToTest],
        });

    });
});