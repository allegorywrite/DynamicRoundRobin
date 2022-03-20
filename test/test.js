const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let addr1;
let addr2;
let addr3;
let addr4;
let addrs;
let RoundRobin;
let APIConsumer;
let RoundRobinFactory;
let APIConsumerFactory;
let ChainlinkClientFactory;
let ChainlinkClient;

describe("ToString Test", () => {
  it("should pass", async () => {
    const [owner] = await ethers.getSigners();
    const ToString = await ethers.getContractFactory("ToString");
    const bytes32 = ethers.utils.formatBytes32String("QmTr9rwUVp2jy8uxpDC7t2")
    console.log(bytes32);
    const Contract = await ToString.deploy();
    const tx = await Contract.bytes32ToString(bytes32);
    expect(tx).to.equal("QmTr9rwUVp2jy8uxpDC7t2");
  });
});

describe("Main Test", () => {
  beforeEach(async function () {
    RoundRobinFactory = await ethers.getContractFactory(
      "DynamicRoundRobin"
    );
    APIConsumerFactory = await ethers.getContractFactory(
      "APIConsumer"
    );
    ChainlinkClientFactory = await ethers.getContractFactory(
      "ChainlinkClient"
    );
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    RoundRobin = await RoundRobinFactory.deploy("initialUri");
    APIConsumer = await APIConsumerFactory.deploy();
    ChainlinkClient = await ChainlinkClientFactory.deploy();
  })

  describe("Transaction Test", () => {
    it("Mint", async () => {
      const MintTx = await RoundRobin.createPlainRobin();
      await MintTx.wait();
      expect(await RoundRobin.balanceOf(owner.address)).to.be.equal(1);
    })

    it("Inherit only once", async () => {
      const MintTx = await RoundRobin.createPlainRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      expect(await RoundRobin.balanceOf(addr1.address)).to.be.equal(1);
    })

    it("Inherit twice", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const MintTx2 = await RoundRobin.connect(addr1).Inherit(addr2.address, 0);
      await MintTx2.wait();
      expect(await RoundRobin.getSuccessors(0)).to.be.equal(3);
    })

    it("Inherit four times", async () => {
      const MintTx = await RoundRobin.createPlainRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const MintTx2 = await RoundRobin.connect(addr1).Inherit(addr2.address, 0);
      await MintTx2.wait();
      const MintTx3 = await RoundRobin.connect(addr2).Inherit(addr3.address, 0);
      await MintTx3.wait();
      const MintTx4 = await RoundRobin.connect(addr3).Inherit(addr4.address, 0);
      await MintTx4.wait();
      expect(await RoundRobin.getGrade(0)).to.be.equal(1);
    })
  })

  describe("Connect Test", () => {
    it("Should pass user name", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const successorId = await RoundRobin.getSuccessors(0);
      const url = await RoundRobin.tokenURI(0);
      console.log(url);
      expect(await RoundRobin.getSuccessorName(0,successorId)).to.be.equal("tomoking")
    })

    it("Should pass profile username", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const uri = await RoundRobin.tokenURI(0)
      expect(uri).to.be.equal("uri");
    })
  })
})