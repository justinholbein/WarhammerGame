const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('WarhammerGame');
  const gameContract = await gameContractFactory.deploy(
      ["Bright Wizard", "Vampire Count", "Warrior Priest"],
      ["QmXf7CVHJgD5xMNqjeK5Nb3VRa7QUB8whf1QWhBbD59wQD",
      "QmdjjV8YD8d4Gm7Eww8VRE3xXkDpiyQ4utxWUpJCdETuY8",
      "QmcW7NKbVCNrnqu2rR4XHnz259FGDA5i1NaVVknc46Bpqa"],
      [1500, 2500, 3250],
      [111, 450, 275],
      [220, 375, 450],
      [477, 275, 125],
      [120, 275, 477],
      "Ulzulagoth, Blight Prophet",
      "QmX1D3SK9h9VRdYJBJdHmrdbLcxaEuwBCQVZTKpRLie3CP",
      13000,
      250
      // 300,
      // 400,
      // 400
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;
  txn = await gameContract.mintCharacterNft(2);
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();