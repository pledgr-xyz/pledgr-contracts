const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Pledge", function () {
  describe("deployment", () => {
    it("Should set storage correctly", async function () {
      const Pledge = await ethers.getContractFactory("PledgeV1");
      const pledge = await Pledge.deploy(
        ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"],
        [40]
      );
      await pledge.deployed();

      expect(
        await pledge.getReceiverPercent(
          "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        )
      ).to.equal(40);
    });
  });
});
