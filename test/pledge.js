const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const { provider } = waffle;

describe("Pledge", () => {
  describe("deployment", () => {
    it("Should set storage correctly", async function () {
      const [_, addrA] = await ethers.getSigners();

      const Pledge = await ethers.getContractFactory("PledgeV1");
      const pledge = await Pledge.deploy([addrA.address], [40]);
      await pledge.deployed();

      expect(await pledge.getReceiverPercent(addrA.address)).to.equal(40);
    });
  });

  describe("recieve", () => {
    it("with one receiver", async () => {
      const [_, receiver, sender] = await ethers.getSigners();
      expect(await provider.getBalance(receiver.address)).to.equal(
        ethers.utils.parseUnits("10000.0")
      );

      const Pledge = await ethers.getContractFactory("PledgeV1");
      const pledge = await Pledge.deploy([receiver.address], [40]);
      await pledge.deployed();

      const tx = await sender.sendTransaction({
        from: sender.address,
        to: pledge.address,
        value: ethers.utils.parseEther("1"),
      });
      const txReceipt = await tx.wait();

      expect(await provider.getBalance(receiver.address)).to.equal(
        ethers.utils.parseUnits("10000.4")
      );
      expect(await provider.getBalance(sender.address)).to.equal(
        ethers.utils
          .parseEther("10000")
          .sub(ethers.utils.parseEther("0.6"))
          .sub(txReceipt.gasUsed.mul(txReceipt.effectiveGasPrice))
      );
    });
  });
});
