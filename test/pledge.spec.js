const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const { provider } = waffle;

describe("Pledge", () => {
  let pledge;
  let proxy;

  const deployContracts = async () => {
    const Pledge = await ethers.getContractFactory("PledgeV1");
    pledge = await Pledge.deploy();
    await pledge.deployed();

    const Proxy = await ethers.getContractFactory("PledgeProxy");
    proxy = await Proxy.deploy(pledge.address);
    await proxy.deployed();
  };

  it("sets payouts", async () => {
    [_, receiver, sender] = await ethers.getSigners();
    await deployContracts();
    await proxy.addPayout({ addr: receiver.address, percent: 40 });

    const payout = await pledge.payouts(proxy.owner(), 0);

    expect(payout.addr).to.equal(receiver.address);
    expect(payout.percent).to.equal(40);
  });

  describe("distribute", () => {
    describe("with one receiver", async () => {
      let receiver;
      let sender;

      beforeEach(async () => {
        [_, receiver, sender] = await ethers.getSigners();

        await deployContracts();
        await proxy.addPayout({ addr: receiver.address, percent: 40 });
      });

      it("executes distribution correctly", async () => {
        const initialReceiverBalance = await provider.getBalance(
          receiver.address
        );
        const ownerAddr = proxy.owner();
        const initialOwnerBalance = await provider.getBalance(ownerAddr);

        const tx = await sender.sendTransaction({
          from: sender.address,
          to: proxy.address,
          value: ethers.utils.parseEther("1"),
        });

        const txR = await tx.wait();
        console.log("Transaction gas:", txR.gasUsed);

        expect(await provider.getBalance(receiver.address)).to.equal(
          initialReceiverBalance.add(ethers.utils.parseEther("0.4"))
        );
        expect(await provider.getBalance(ownerAddr)).to.equal(
          initialOwnerBalance.add(ethers.utils.parseEther("0.6"))
        );
      });
    });
  });
});
