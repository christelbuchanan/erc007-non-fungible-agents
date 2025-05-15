require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  // Disable the solidity analyzer which requires native addons
  mocha: {
    timeout: 40000
  },
  // Add this to disable native addons
  allowUnlimitedContractSize: true,
  // Disable the solidity analyzer
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
