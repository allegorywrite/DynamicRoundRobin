const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let addr1;
let addr2;
let addr3;
let addr4;
let addrs;
let RoundRobin;
let RoundRobinFactory;
let ToStringFactory;
let ToString;
const ownerAddr = "0x16ea840cfA174FdAC738905C4E5dB59Fd86912a1";

describe("ToString Test", () => {

  beforeEach(async function () {
    ToStringFactory = await ethers.getContractFactory(
      "ToString"
    );
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    ToString = await ToStringFactory.deploy();
  })
  
  it("should pass", async () => {
    const bytes32 = ethers.utils.formatBytes32String("QmTr9rwUVp2jy8uxpDC7t2")
    console.log(bytes32);
    const tx = await ToString.bytes32ToString(bytes32);
    expect(tx).to.equal("QmTr9rwUVp2jy8uxpDC7t2");
  });
  
  it("should convert address to string", async () => {
    const out = await ToString.addressToString(ownerAddr);
    expect(out).to.equal("0x16ea840cfa174fdac738905c4e5db59fd86912a1");
  });
});

describe("Main Test", () => {
  beforeEach(async function () {
    RoundRobinFactory = await ethers.getContractFactory(
      "DynamicRoundRobin"
    );
    [owner, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();
    RoundRobin = await RoundRobinFactory.deploy("initialUri");

  })

  describe("Transaction Test", () => {
    xit("Mint", async () => {
      const MintTx = await RoundRobin.createPlainRobin();
      await MintTx.wait();
      expect(await RoundRobin.balanceOf(owner.address)).to.be.equal(1);
    })

    xit("Inherit only once", async () => {
      const MintTx = await RoundRobin.createPlainRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      expect(await RoundRobin.balanceOf(addr1.address)).to.be.equal(1);
    })

    xit("Inherit twice", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const MintTx2 = await RoundRobin.connect(addr1).Inherit(addr2.address, 0);
      await MintTx2.wait();
      expect(await RoundRobin.getSuccessors(0)).to.be.equal(3);
    })

    xit("Inherit four times", async () => {
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
    xit("Should pass user name", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const successorId = await RoundRobin.getSuccessors(0);
      const url = await RoundRobin.tokenURI(0);
      console.log(url);
      expect(await RoundRobin.getSuccessorName(0,successorId)).to.be.equal("tomoking")
    })

    xit("Should pass profile username", async () => {
      const MintTx = await RoundRobin.createRobin();
      await MintTx.wait();
      const MintTx1 = await RoundRobin.Inherit(addr1.address, 0);
      await MintTx1.wait();
      const uri = await RoundRobin.tokenURI(0)
      expect(uri).to.be.equal("uri");
    })
  })
})