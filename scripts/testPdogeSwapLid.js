const { getBigNumber, getContract } = require("./shared");
const pancakePair = require("./abis/PancakePair.json");
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
   /*  await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: ["0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26"],
    }); */

    
    const signer = await ethers.getSigner("0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26")

   /*  const network = await ethers.getDefaultProvider().getNetwork();
    console.log("chainId: ", network.chainId);
    console.log("Network chain name=", network.name); */

    const pdoge = await ethers.getContractAt(
        "MockERC20",
        "0xe64D316e6AAe57f322A179b118689708b368E163"
    );

    const busd = await ethers.getContractAt(
        "MockERC20",
        "0x92325A71cdacf88E45aD12597EE59E662342D03a"
    );


    // Deploying additional tokens
    const tokens = [
        { name: "BUSD", symbol: "BUSD" },
        { name: "PolyDoge", symbol: "PDOGE" },
    ];

    /*  const additionalTokens = {};
     for (const token of tokens) {
       console.log(`Deploying ${token.name}...`);
       const tokenContract = await MockERC20.deploy(
         token.name,
         token.symbol,
         getBigNumber(100000000000)
       );
       await tokenContract.deployed();
       additionalTokens[`${token.symbol}`] = tokenContract.address;
       console.log(`Deployed ${token.name} at ${tokenContract.address}`);
     } 
   
      const pdoge = await ethers.getContractAt(
       "MockERC20",
       additionalTokens["PDOGE"]
     ); */

    const FuelToken = await ethers.getContractFactory("FuelToken");
    const fuelToken = await FuelToken.connect(signer).deploy();
    await fuelToken.deployed();

    const MasterChefV2 = await ethers.getContractFactory("MasterChefV2");
    const masterChefV2 = await MasterChefV2.connect(signer).deploy(
        fuelToken.address,
        "0xaEc43A98f2Ba215b23dCDd3ac5707959A3bf3E26",
        17164376,
        pdoge.address,
        busd.address
    );

    await masterChefV2.deployed();
    // Transfer Ownership of FUEL to masterchef
    console.log("transferOwnership to MasterChef");
    await fuelToken.connect(signer).transferOwnership(masterChefV2.address);
    console.log("transferOwnership done");

    console.log("increase allowance");
    await pdoge.connect(signer).increaseAllowance(masterChefV2.address, getBigNumber(20263999999));

    console.log("add pdoge");
    await masterChefV2.connect(signer).add(2000, "0xe64D316e6AAe57f322A179b118689708b368E163", 300, true);

    const busd_pdoge = getContract("0x8Ef6125DE5F84056287e1f37dE821A808007886D", pancakePair)


    console.log("Total supply: ", await busd_pdoge.totalSupply());
    console.log("BUSD IN PAIR: ", await busd.balanceOf(busd_pdoge.address));
    console.log("PDOGE IN PAIR: ", await pdoge.balanceOf(busd_pdoge.address));
    console.log("PDOGE of user: ", await pdoge.balanceOf(signer.address));
    console.log("depsit pdoge");
    await masterChefV2.connect(signer).deposit(0, getBigNumber(20263999999), {gasLimit: 250000});
    console.log("deposit success");


    console.log("Total supply: ", await busd_pdoge.totalSupply());
    console.log("BUSD IN PAIR: ", await busd.balanceOf(busd_pdoge.address));
    console.log("PDOGE IN PAIR: ", await pdoge.balanceOf(busd_pdoge.address));

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
