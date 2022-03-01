const fs = require("fs");
const { ethers } = require("hardhat");
const {createPair,getBigNumber} = require("./shared");
const AdditionalTokens = require("./args/additional_tokens_dev.json");

require("dotenv").config();

const ROUTER_ADDRESS = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; // pancake testnet
const FACTORY_ADDRESS = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc"; // pancake testnet


async function createPairs(fuel){
  const signers = await ethers.getSigners();
  const alice = signers[0];
  let pairsContent = {}

  const fuel_busd = await createPair(
    ROUTER_ADDRESS,
    FACTORY_ADDRESS,
    fuel, // on bsc testnet FUEL
    AdditionalTokens.BUSD,
    getBigNumber(7500),
    getBigNumber(75000),
    alice.address,
    alice
  );

  pairsContent['fuel_busd'] = fuel_busd
  console.log(`created FUEL_BUSD pair at ${fuel_busd}`);

 /*  const fuel_wbnb = await createPair(
    ROUTER_ADDRESS,
    FACTORY_ADDRESS,
    fuel, // on bsc testnet FUEL
    AdditionalTokens.WBNB,
    getBigNumber(2800),
    getBigNumber(480),
    alice.address,
    alice
  );

  pairsContent['fuel_wbnb'] = fuel_wbnb
  console.log(`created FUEL_WBNB pair at ${fuel_wbnb}`); */


  fs.writeFileSync(
    "./scripts/args/pairs_dev.json",
    JSON.stringify(pairsContent),
    { flag: "w+" }
  );
}

module.exports = {
  createPairs
}
