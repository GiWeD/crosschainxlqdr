require("@nomiclabs/hardhat-waffle");

require('@openzeppelin/hardhat-upgrades');

require("@nomiclabs/hardhat-etherscan");

require("@nomiclabs/hardhat-web3");

//require("hardhat-gas-reporter");

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
        version: "0.8.2",
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
      accounts: [`0x${"2e83f39ce3804d58f75128211c55dc093be88f00313ca1b5cbc796f16e72da1d"}`]
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
      accounts: [`0x${"2e83f39ce3804d58f75128211c55dc093be88f00313ca1b5cbc796f16e72da1d"}`]
    },


    hardhat: {
      forking: {
          url: "https://rpc.ftm.tools", // command line:  npx hardhat node --fork https://rpcapi.fantom.network,
      },
      //accounts: []
    }
  
  },

  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "SNEXDE2Z58N9Q6KUV1AAYGH214DIZJSS2J"
  }

}