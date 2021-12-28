const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const { provider } = waffle;

describe("Pledge", () => {
  describe("deployment", () => {
    it("Should set storage correctly", async function () {
      const [_, receiver] = await ethers.getSigners();

      const Pledge = await ethers.getContractFactory("PledgeV1");
      const pledge = await Pledge.deploy([
        {
          addr: receiver.address,
          percent: 40,
        },
      ]);
      await pledge.deployed();

      expect(await pledge.getReceiverPercent(receiver.address)).to.equal(40);
    });
  });

  describe("recieve", () => {
    describe("with one receiver", async () => {
      let receiver;
      let sender;
      let pledge;

      beforeEach(async () => {
        [_, receiver, sender] = await ethers.getSigners();

        const Pledge = await ethers.getContractFactory("PledgeV1");
        pledge = await Pledge.deploy([
          {
            addr: receiver.address,
            percent: 40,
          },
        ]);
        await pledge.deployed();
      });

      it("executes distribution correctly", async () => {
        const initialReceiverBalance = await provider.getBalance(
          receiver.address
        );
        const initialOwnerBalance = await provider.getBalance(pledge.owner());

        await sender.sendTransaction({
          from: sender.address,
          to: pledge.address,
          value: ethers.utils.parseEther("1"),
        });

        expect(await provider.getBalance(receiver.address)).to.equal(
          initialReceiverBalance.add(ethers.utils.parseEther("0.4"))
        );
        expect(await provider.getBalance(pledge.owner())).to.equal(
          initialOwnerBalance.add(ethers.utils.parseEther("0.6"))
        );
      });
    });
  });

  // describe("setReceiverPercent", () => {
  //   it("when receiver exists", () => {
  //     // TODO
  //   });

  //   it("when receiver does not exist", () => {
  //     // TODO
  //   });
  // });
});
