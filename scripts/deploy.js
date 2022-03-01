const hre = require("hardhat");
const AdditionalTokens = require("./args/additional_tokens_dev.json");
const { BigNumber } = ethers;
const fs = require("fs");


const startBlock = 16369474
const oneDay = 28800
const fiveDays = 144000
const feeAddress = "0xE936dAf67f6C33997CC695Ce6bd8eA2e141A1041" //test-acc2
const fuelPerBlock = BigNumber.from("100000000000000000")

async function main() {

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


  //FUEL REEDEM
  const FuelReedem = await hre.ethers.getContractFactory("FuelReedem");
  const fuelReedem = await FuelReedem.deploy(startBlock + fiveDays, preFuelToken.address, fuelToken.address);

  await fuelReedem.deployed();

  console.log("FuelReedem deployed to:", fuelReedem.address);
  contract_addresses["FUEL_REEDEM_CONTRACT"] = fuelReedem.address


  //MASTERCHEF
  const MasterChefV2 = await hre.ethers.getContractFactory("MasterChefV2");
  const masterChefV2 = await MasterChefV2.deploy(fuelToken.address, feeAddress, startBlock + fiveDays + fiveDays);

  await masterChefV2.deployed();

  console.log("MasterChefV2 deployed to:", masterChefV2.address);
  contract_addresses["MASTERCHEF"] = masterChefV2.address


  // Transfer Ownership of FUEL to masterchef
  console.log("transferOwnership to MasterChef");
  await fuelToken.transferOwnership(masterChefV2.address)
  console.log("transferOwnership done");


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
