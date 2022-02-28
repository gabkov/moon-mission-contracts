const { getBigNumber } = require("./shared");

async function main() {
  const pdoge = await ethers.getContractAt(
    "MockERC20",
    "0xe64D316e6AAe57f322A179b118689708b368E163"
  );
  //const pdoge = await MockERC20.attach("0xe64D316e6AAe57f322A179b118689708b368E163");

  for (let index = 0; index < 1000; index++) {
    await pdoge.faucetToken(getBigNumber(500000));
      
  }
  await pdoge.faucetToken(getBigNumber(500000));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
