const fs = require("fs");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { getBigNumber } = require("./shared");

require("dotenv").config();

/**
 * This script is only for testnet, don't use it on mainnet
 */
async function main() {
  const signers = await hre.ethers.getSigners();
  console.log(
    "Preparing ERC20 tokens and Writing result in ./scripts/args/additional_tokens_dev.json..."
  );

  
  const MockERC20 = await hre.ethers.getContractFactory("MockERC20");
 
  // Deploying additional tokens
  const tokens = [
    //{ name: "BUSD", symbol: "BUSD" },
    //{ name: "Tether", symbol: "USDT" },
    //{ name: "WBNB", symbol: "WBNB" },
    //{ name: "BTCB", symbol: "BTCB" },
    //{ name: "Ethereum", symbol: "ETH" },
    //{ name: "PancakeSwap Token", symbol: "CAKE" },
    { name: "PolyDoge", symbol: "PDOGE" },
  ];

  const additionalTokens = {};
  for (const token of tokens) {
    console.log(`Deploying ${token.name}...`);
    const tokenContract = await MockERC20.deploy(
      token.name,
      token.symbol,
      getBigNumber(1000000000)
    );
    await tokenContract.deployed();
    additionalTokens[`${token.symbol}`] = tokenContract.address;
    console.log(`Deployed ${token.name} at ${tokenContract.address}`);
  }

  console.log("Writing result...");
  await fs.writeFileSync(
    "./scripts/args/additional_tokens_dev.json",
    JSON.stringify(additionalTokens),
    { flag: "w+" }
  );

  console.log("==END==");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
