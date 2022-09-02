const { hexValue } = require('ethers/lib/utils');
const { ethers, upgrades } = require('hardhat');

const { erc20Abi } = require("../scripts/Abi.js")
/*
const jsonabi  = require("C:/Users/giuli/Desktop/Solidity/crosschainxLQDR/crosschainxlqdr/artifacts/contracts/CcLQDRController.sol/CcLQDRController.json")
*/
const jsonabi2  = require("C:/Users/giuli/Desktop/Solidity/crosschainxLQDR/crosschainxlqdr/artifacts/contracts/AnyswapTokenClient.sol/AnyswapTokenClient.json")


const anyCallProxyFTMTestnet = ethers.utils.getAddress("0xD7c295E399CA928A3a14b01D760E794f1AdF8990")
const anyCallProxyRinkTestnet = ethers.utils.getAddress("0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02")

async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    /*vaultFactory = await ethers.getContractFactory("LQDRVault");
    vaultContract = await upgrades.deployProxy(vaultFactory,[], {initializer: 'initialize'});
    txDeployed = await vaultContract.deployed();   
    console.log('Contract LQDRVault deployed to:', vaultContract.address);

    // string memory _name, string memory _symbol, uint8 _decimals, address _owner, address _vault
    lqdrProxyFactory = await ethers.getContractFactory("LQDR");
    lqdrProxyFactoryContract = await lqdrProxyFactory.deploy( "LiquidDriver", "LQDR", 18, owner.address, vaultContract.address);
    txDeployed = await lqdrProxyFactoryContract.deployed();
    console.log('Contract LQDR deployed to:', lqdrProxyFactoryContract.address);
    console.log('Owner: ', (await lqdrProxyFactoryContract.owner()).toString())


    AnyswapTokenClientFactory = await ethers.getContractFactory("AnyswapTokenClient");
    //address _admin,address _callProxy
    AnyswapTokenClientContract = await AnyswapTokenClientFactory.deploy(owner.address, anyCallProxyRinkTestnet);
    txDeployed = await AnyswapTokenClientContract.deployed();   
    console.log('Contract AnyswapTokenClient deployed to:', AnyswapTokenClientContract.address);*/

    lqdrOriginalContract = new ethers.Contract(ethers.utils.getAddress("0xb456d55463a84c7a602593d55db5a808bf46aac9"), erc20Abi, owner)
    lqdrVaultAddress =  ethers.utils.getAddress("0x9A4EFC0Dd09fc93305b2df737fb1a3f9516aa068")

    tx = await lqdrOriginalContract.approve(lqdrVaultAddress, ethers.utils.parseEther("1000"))
    await tx.wait()

    //anyCallPRoxy = new ethers.Contract(ethers.utils.getAddress("0x852c882963da259168fa7bef2f737c988c3cf5ac"),jsonabi2.abi)




}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });