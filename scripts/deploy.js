const { hexValue } = require('ethers/lib/utils');
const { ethers, upgrades } = require('hardhat');

const { erc20Abi } = require("../scripts/Abi.js")

const jsonabi  = require("C:/Users/giuli/Desktop/Solidity/crosschainxLQDR/crosschainxlqdr/artifacts/contracts/CcLQDRController.sol/CcLQDRController.json")
const jsonabi2  = require("C:/Users/giuli/Desktop/Solidity/crosschainxLQDR/crosschainxlqdr/artifacts/contracts/LQDR.sol/LQDR.json")



const lqdrFtmTestnet = ethers.utils.getAddress("0xb456D55463A84C7A602593D55DB5a808bF46aAc9")
const endpointFtmTestnet = ethers.utils.getAddress("0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf")


const lqdrRinkeby = ethers.utils.getAddress("0xa5DeA425540b943Bf47F57e7ecde67230d48084f")
const endpointRinkeby = ethers.utils.getAddress("0x79a63d6d8BBD5c6dfc774dA79bCcD948EAcb53FA")

async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    

    /*callerFactory = await ethers.getContractFactory("LQDR");
    callerContract = await callerFactory.deploy();
    txDeployed = await callerContract.deployed();
    console.log('Contract LQDR deployed to:', callerContract.address);
    console.log('Owner: ' (await callerContract.owner()).toString())*/


   

    /*vaultFactory = await ethers.getContractFactory("CcLQDRController");
    //constructor(address _lqdr, ILayerZeroEndpoint _endpoint, uint256 _layerZeroChainId)
    input = [lqdrRinkeby, endpointRinkeby, 10001, false]
    vaultContract = await upgrades.deployProxy(vaultFactory,input, {initializer: 'initialize'});
    txDeployed = await vaultContract.deployed();   
    console.log('Contract CcLQDRController deployed to:', vaultContract.address);*/

    

    const ccaddr = ethers.utils.getAddress("0xC7dB491819C0e9bA90e59b5719A71676Afa439b6") // rinke 
    const contract = new ethers.Contract(ccaddr, jsonabi.abi, owner)
    console.log(await contract.owner())
    /*tx = await contract.addLayerZeroChainId(10012, 250 );
    tx.wait()
    tx = await contract.addLayerZeroChainId(10001, 42161 );
    tx.wait()*/
    console.log((await contract.layerZeroToChainIds(10001)) .toString() )
    console.log((await contract.layerZeroToChainIds(10012)) .toString() )


    /*tx = await contract.setControllerAddress(10012, "0xa5DeA425540b943Bf47F57e7ecde67230d48084f" ); //FTM
    tx.wait()
    tx = await contract.setControllerAddress(10001, "0xC7dB491819C0e9bA90e59b5719A71676Afa439b6" ); //Rinkeby
    tx.wait()*/

    console.log((await contract.controller(10001)) .toString() )
    console.log((await contract.controller(10012)) .toString() )

    const lqdrContract = new ethers.Contract(lqdrRinkeby, jsonabi2.abi, owner)
    //await lqdrContract.addController(ccaddr)
    
    //await lqdrContract.mint(owner.address,ethers.utils.parseEther("1000"))

    //function bridgeTo(uint256 _dstLayerZeroChainId, uint256 _amount, address _to, uint256 _extraGas) external payable nonReentrant {
    //await lqdrContract.approve(ccaddr, ethers.utils.parseEther("100"))
    //console.log(await  lqdrContract.allowance(owner.address, ccaddr))
    await contract.bridgeTo(10012, ethers.utils.parseEther("10"), owner.address, 200000, {gasLimit: 2000000,value: ethers.utils.parseEther("0.2")})

    //console.log( (await contract.lqdr()).toString() )



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });