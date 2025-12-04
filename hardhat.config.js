require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },

  // NEU: V2-Config
  verify: {
    etherscan: {
      // dein normaler Etherscan-Key, funktioniert jetzt
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
};