const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const { provider } = waffle;

describe("Pledge", () => {
  let pledge;

  const deployContract = async (deployArgs) => {
    const Pledge = await ethers.getContractFactory("PledgeV1");
    pledge = await Pledge.deploy(deployArgs);
    await pledge.deployed();
  };

  describe("deployment", () => {
    it("Should set storage correctly", async function () {
      const [_, receiver] = await ethers.getSigners();

      await deployContract([
        {
          addr: receiver.address,
          percent: 40,
        },
      ]);

      // TODO mock `setPayouts` and assert that `setPayouts` was called with correct args.
      expect(await pledge.receiversToPercent(receiver.address)).to.equal(40);
    });
  });

  describe("distribute", () => {
    describe("with one receiver", async () => {
      let receiver;
      let sender;

      beforeEach(async () => {
        [_, receiver, sender] = await ethers.getSigners();

        await deployContract([
          {
            addr: receiver.address,
            percent: 40,
          },
        ]);
      });

      it("executes distribution correctly", async () => {
        const initialReceiverBalance = await provider.getBalance(
          receiver.address
        );
        const initialOwnerBalance = await provider.getBalance(pledge.owner());

        // await pledge.connect(sender).distribute(ethers.utils.parseEther("1"));
        const tx = await sender.sendTransaction({
          from: sender.address,
          to: pledge.address,
          value: ethers.utils.parseEther("1"),
        });

        const txR = await tx.wait();
        console.log("Transaction gas:", txR.gasUsed);

        expect(await provider.getBalance(receiver.address)).to.equal(
          initialReceiverBalance.add(ethers.utils.parseEther("0.4"))
        );
        expect(await provider.getBalance(pledge.owner())).to.equal(
          initialOwnerBalance.add(ethers.utils.parseEther("0.6"))
        );
      });
    });
  });

  describe("setPayouts", () => {
    describe("with no existing payouts", () => {
      beforeEach(async () => {
        await deployContract([]);
      });

      it("sets `receivers` and `receiversToPercent` storage", async () => {
        [_, receiver] = await ethers.getSigners();

        await pledge.setPayouts([
          {
            addr: receiver.address,
            percent: 40,
          },
        ]);

        expect(await pledge.receivers(0)).to.equal(receiver.address);
        expect(await pledge.receiversToPercent(receiver.address)).to.equal(40);
      });
    });

    describe("with existing payouts", () => {
      let receiverA;
      let receiverB;

      beforeEach(async () => {
        [_, receiverA, receiverB] = await ethers.getSigners();

        await deployContract([
          {
            addr: receiverA.address,
            percent: 40,
          },
        ]);
      });

      it("overwrites `receivers` and `receiversToPercent` storage", async () => {
        await pledge.setPayouts([
          {
            addr: receiverA.address,
            percent: 20,
          },
          {
            addr: receiverB.address,
            percent: 60,
          },
        ]);
        expect(await pledge.receivers(0)).to.equal(receiverA.address);
        expect(await pledge.receiversToPercent(receiverA.address)).to.equal(20);

        expect(await pledge.receivers(1)).to.equal(receiverB.address);
        expect(await pledge.receiversToPercent(receiverB.address)).to.equal(60);
      });
    });
  });

  describe("setReceiverPercent", () => {
    let receiverA;
    let receiverB;

    beforeEach(async () => {
      [_, receiverA, receiverB] = await ethers.getSigners();

      await deployContract([
        {
          addr: receiverA.address,
          percent: 40,
        },
      ]);
    });

    describe("when receiver exists", () => {
      it("updates receiver percentage", async () => {
        await pledge.setReceiverPercent(receiverA.address, 30);

        expect(await pledge.receiversToPercent(receiverA.address)).to.equal(30);
      });
    });

    describe("when receiver does not exist", () => {
      it("updates receiver percentage", async () => {
        await pledge.setReceiverPercent(receiverB.address, 20);

        expect(await pledge.receivers(0)).to.equal(receiverA.address);
        expect(await pledge.receivers(1)).to.equal(receiverB.address);
        expect(await pledge.receiversToPercent(receiverB.address)).to.equal(20);
      });
    });
  });
});
