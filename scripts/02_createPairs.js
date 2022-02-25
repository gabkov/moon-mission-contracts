const fs = require("fs");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const {
  createPair,
  createPairETH,
  getContract,
  getBigNumber,
} = require("./shared");
const UniswapV2Router = require("./abis/UniswapV2Router.json");
const AdditionalTokens = require("./args/additional_tokens_dev.json");

require("dotenv").config();

const ROUTER_ADDRESS = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; // pancake testnet
const FACTORY_ADDRESS = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc"; // pancake testnet


/**
 * This script is only for testnet, don't use it on mainnet
 */
async function main() {
  console.log(
    "Preparing liquidity pairs and Writing result in scripts/args/pairs_dev.json..."
  );
  const signers = await ethers.getSigners();
  const alice = signers[0];

  // const routerContract = getContract(ROUTER_ADDRESS, UniswapV2Router);
  // const factory = await routerContract.factory();

  // // create DCAU_Wrapped Token pair
  // const wrapped_pair = await createPairETH(
  //   ROUTER_ADDRESS,
  //   FACTORY_ADDRESS,
  //   "0xF72Cc18218058722a3874b63487F1B4C82F92081",
  //   getBigNumber(1000),
  //   getBigNumber(1),
  //   alice.address,
  //   alice
  // );

  // console.log(`Wrapped token pair at ${wrapped_pair}`);

  // console.log("[factory]", factory);

  const tokens = [
    //{ symbol: "BUSD", address: AdditionalTokens.BUSD },
    { symbol: "WBNB", address: AdditionalTokens.WBNB },
  ];

  let pairsContent = {}

  for (const token of tokens) {
    console.log(`creating FUEL_${token.symbol} pair...`);
    const pair = await createPair(
      ROUTER_ADDRESS,
      FACTORY_ADDRESS,
      "0x51efE7b080BB9704610c5a6d777676B111E6226d", // on bsc testnet FUEL
      token.address,
      getBigNumber(300),
      getBigNumber(10000),
      alice.address,
      alice
    );

    pairsContent['fuel_' + token.symbol.toLowerCase()] = pair

    console.log(`created FUEL_${token.symbol} pair at ${pair}`);
  }

  fs.writeFileSync(
    "./scripts/args/pairs_dev.json",
    JSON.stringify(pairsContent),
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
