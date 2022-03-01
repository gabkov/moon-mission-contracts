const hre = require("hardhat");
const AdditionalTokens = require("./args/additional_tokens_dev.json");
const pools = require("./args/pools.json");
const pairedTokens = require("./args/pairs_dev.json");
const { BigNumber } = ethers;
const fs = require("fs");
const { createPairs } = require("./02_createPairs");
const { getBigNumber } = require("./shared");
const ERC20 = require("./abis/ERC20.json");


const startBlock = 17181311
const oneDay = 28800
const oneHour = 1200
const fiveDays = 144000
const feeAddress = "0xE936dAf67f6C33997CC695Ce6bd8eA2e141A1041" //test-acc2

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


  //await createPairs(fuelToken.address)

  //FUEL REEDEM
  const FuelReedem = await hre.ethers.getContractFactory("FuelReedem");
  const fuelReedem = await FuelReedem.deploy(startBlock + oneHour, preFuelToken.address, fuelToken.address);

  await fuelReedem.deployed();

  console.log("FuelReedem deployed to:", fuelReedem.address);
  contract_addresses["FUEL_REEDEM_CONTRACT"] = fuelReedem.address

  //console.log("Sending 30.000 FUEL to FuelReedem")
  //const FUEL = new ethers.Contract(fuelToken.address, ERC20 , alice);//The wallet itself works fine
  //await FUEL.transfer(fuelReedem.address, getBigNumber(30000))
  //console.log("Sent 30.000 FUEL to FuelReedem")

  //MASTERCHEF
  const MasterChefV2 = await hre.ethers.getContractFactory("MasterChefV2");
  const masterChefV2 = await MasterChefV2.deploy(fuelToken.address, feeAddress, startBlock + oneHour + oneHour);

  await masterChefV2.deployed();

  console.log("MasterChefV2 deployed to:", masterChefV2.address);
  contract_addresses["MASTERCHEF"] = masterChefV2.address

  // Transfer Ownership of FUEL to masterchef
  //console.log("transferOwnership to MasterChef");
  //await fuelToken.transferOwnership(masterChefV2.address)
  //console.log("transferOwnership done");

 /*  console.log("Adding pools");
  await masterChefV2.add(1000, fuelToken.address, 0, true) // 0
  await masterChefV2.add(500, pools.PDOGE, 300, true) // 1
  await masterChefV2.add(500, pools.BUSD, 400, true) // 2
  await masterChefV2.add(500, pools.WBNB, 400, true) // 3
  await masterChefV2.add(700, pools.BTCB, 400, true) // 4
  await masterChefV2.add(600, pools.ETH, 400, true) // 5
  await masterChefV2.add(500, pools.CAKE, 400, true) // 6
  await masterChefV2.add(1000, pairedTokens.fuel_busd, 0, true) // 7
  await masterChefV2.add(1000, pairedTokens.fuel_wbnb, 0, true) // 8
  await masterChefV2.add(1000, pools.BUSD_PDOGE, 200, true) // 9
  await masterChefV2.add(1000, pools.BUSD_WBNB, 400, true) //10
  await masterChefV2.add(1000, pools.BUSD_USDT, 400, true) // 11
  await masterChefV2.add(1000, pools.BUSD_USDC, 400, true) // 12
  await masterChefV2.add(1000, pools.BTCB_ETH, 400, true) // 13
  console.log("Pools added"); */

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
