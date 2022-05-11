import { expect } from "chai";
import { ethers } from "hardhat";

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });

  it("Market", async function () {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    const MarketStorage = await ethers.getContractFactory("MarketStorage");
    const market = await MarketStorage.deploy();
    await market.deployed();

    const bet0 = await market.addBet(1, 1, {
      value: ethers.utils.parseEther("0.003"),
    });
    await bet0.wait();

    const market1 = await market.connect(addr1);
    const bet1 = await market1.addBet(1, 0, {
      value: ethers.utils.parseEther("0.005"),
    });
    await bet1.wait();

    const market2 = await market.connect(addr2);
    const bet2 = await market2.addBet(1, 0, {
      value: ethers.utils.parseEther("0.006"),
    });
    await bet2.wait();

    const market3 = await market.connect(addr3);
    // await market.connect(addr3);
    const bet3 = await market3.addBet(1, 1, {
      value: ethers.utils.parseEther("0.006"),
    });
    await bet3.wait();

    const market0 = await market.connect(owner);
    const end = await market0.endMarket(1, 1);
    await end.wait();
  });
});
