const hre = require("hardhat");
const AdditionalTokens = require("./args/additional_tokens_dev.json");
const pools = require("./args/pools.json");
const pairedTokens = require("./args/pairs_dev.json");
const { BigNumber } = ethers;
const fs = require("fs");
const { createPairs } = require("./02_createPairs");
const { getBigNumber } = require("./shared");
const ERC20 = require("./abis/ERC20.json");


const startBlock = 22861569
const oneDay = 28800
const oneHour = 1200
const fiveDays = 144000
const feeAddress = "0x36e6C7b333E94af8E20519b113DeC68Cee224Fd0" //account 2

async function main() {
  const signers = await ethers.getSigners();
  const alice = signers[0];

  const contract_addresses = {}

  //PRE-FUEL
  const PreFuelToken = await hre.ethers.getContractFactory("PreFuelToken");
  const preFuelToken = await PreFuelToken.deploy(startBlock); 

  await preFuelToken.deployed();

  console.log("PreFuelToken deployed to:", preFuelToken.address);
  contract_addresses["PRE_FUEL_TOKEN_CONTRACT"] = preFuelToken.address

  //FUEL
  const FuelToken = await hre.ethers.getContractFactory("FuelToken");
  const fuelToken = await FuelToken.deploy();

  await fuelToken.deployed();

  console.log("FuelToken deployed to:", fuelToken.address);
  contract_addresses["FUEL_TOKEN_ADDRESS"] = fuelToken.address


  await createPairs(fuelToken.address)

  //FUEL REEDEM
  const FuelReedem = await hre.ethers.getContractFactory("FuelReedem");
  const fuelReedem = await FuelReedem.deploy(startBlock + oneHour, preFuelToken.address, fuelToken.address);

  await fuelReedem.deployed();

  console.log("FuelReedem deployed to:", fuelReedem.address);
  contract_addresses["FUEL_REEDEM_CONTRACT"] = fuelReedem.address


  //MASTERCHEF
  const MasterChefV2 = await hre.ethers.getContractFactory("MasterChefV2");
  const masterChefV2 = await MasterChefV2.deploy(fuelToken.address, feeAddress, startBlock + oneHour + oneHour);

  await masterChefV2.deployed();

  console.log("MasterChefV2 deployed to:", masterChefV2.address);
  contract_addresses["MASTERCHEF"] = masterChefV2.address

  console.log("Writing result...");
  fs.writeFileSync(
    "./scripts/deployed/contract_addresses.json",
    JSON.stringify(contract_addresses),
    { flag: "w+" }
  );
  console.log("DONE");
}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
