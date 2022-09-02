require("@nomiclabs/hardhat-waffle");

require('@openzeppelin/hardhat-upgrades');

require("@nomiclabs/hardhat-etherscan");

require("@nomiclabs/hardhat-web3");

//require("hardhat-gas-reporter");

const { PRIVATEKEY } = require("./pvkey.js")


module.exports = {
  // latest Solidity version
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ]
  },

  networks: {

    // fantomTestnet network specification
    fantomTestnet: {
      url: `https://rpc.testnet.fantom.network`,
      chainId: 0xfa2,
      gas: 2100000,
      gasPrice: 8000000000,
      accounts: PRIVATEKEY,
      chainId: 4002
    },


    // fantomOpera network specification
    fantomOpera: {
      url: `https://rpc.ftm.tools/`,
      chainId: 250,
      //accounts: [`0x${""}`], //
      gas: 1000000
    },

    rinkeby: {
      url: "https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
      chainId: 4,
      accounts: PRIVATEKEY
    },


    hardhat: {
      forking: {
          url: "https://rpc.testnet.fantom.network", // command line:  npx hardhat node --fork https://rpcapi.fantom.network,
          chainId: 4002
      },
      //accounts: []
    }
  
  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "CF4BJJYW47K994VENYU61VVY87KI7Q7W6U" //ftm: SNEXDE2Z58N9Q6KUV1AAYGH214DIZJSS2J  eth: CF4BJJYW47K994VENYU61VVY87KI7Q7W6U
  }

}