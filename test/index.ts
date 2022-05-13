import { expect, assert } from "chai";
import { ethers } from "hardhat";
import { MarketStorage, MarketStorage__factory } from "../typechain";
const marketHolder = {
  marketId: 1,
  question: "WAGMI?",
  description: "No one knows",
  marketType: 0,
  options: ["yes", "no"],
  resolverUrl: "https://ashishkumars.com/coolpanda/resolve/1",
  creatorImageHash: "https://ashishkumars.com/coolpanda/1/img.jpg",
  endTimestamp: Date.now() + 1000,
};
let marketStorage: MarketStorage__factory;
let market: MarketStorage;

describe("MarketStorage Tests", () => {
  beforeEach("Creating Market", async () => {
    marketStorage = await ethers.getContractFactory("MarketStorage");
    market = await marketStorage.deploy();
    await market.deployed();

    const createMarketTx = await market.createMarket(
      marketHolder.marketId,
      marketHolder.question,
      marketHolder.description,
      marketHolder.marketType,
      marketHolder.options,
      marketHolder.resolverUrl,
      marketHolder.creatorImageHash,
      marketHolder.endTimestamp
    );
    await createMarketTx.wait();
  });

  it("Creating Market", async () => {
    const totalMarkets = await market.getTotalMarkets();
    expect(totalMarkets).to.equal(1);

    const marketState = await market.marketStates(1);
    expect(marketState).to.equal(0); //0 => BiddingOpen

    const createdMarket = await market.markets(marketHolder.marketId);
    expect(createdMarket.marketId).to.equal(marketHolder.marketId);
    expect(createdMarket.question).to.equal(marketHolder.question);
    expect(createdMarket.description).to.equal(marketHolder.description);
    expect(createdMarket.marketType).to.equal(marketHolder.marketType);
    expect(createdMarket.resolverUrl).to.equal(marketHolder.resolverUrl);
    expect(createdMarket.creatorImageHash).to.equal(
      marketHolder.creatorImageHash
    );
    expect(createdMarket.bidEndTimestamp).to.equal(marketHolder.endTimestamp);
  });

  it("MarketStorage transactions", async () => {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

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
    const bet3 = await market3.addBet(1, 1, {
      value: ethers.utils.parseEther("0.006"),
    });
    await bet3.wait();

    const market0 = await market.connect(owner);
    const end = await market0.endMarket(1, 1);
    await end.wait();

    const marketState = await market.marketStates(1);
    expect(marketState).to.equal(1); //1 => BiddingClosed
  });
});
