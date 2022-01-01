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

  describe("distribute", () => {
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

  // describe("receive", () => {
  //   it("calls `distribute` with msg.value", {
  //     // TODO
  //   });
  // });

  describe("setReceiverPercent", () => {
    let receiver1;
    let receiver2;
    let pledge;

    beforeEach(async () => {
      [_, receiver1, receiver2] = await ethers.getSigners();

      const Pledge = await ethers.getContractFactory("PledgeV1");
      pledge = await Pledge.deploy([
        {
          addr: receiver1.address,
          percent: 40,
        },
      ]);
      await pledge.deployed();
    });

    it("when receiver exists", async () => {
      await pledge.setReceiverPercent(receiver1.address, 30);
      const updatedReceiverPercent = await pledge.getReceiverPercent(
        receiver1.address
      );
      console.log("updated receiver percent: ", updatedReceiverPercent);
      expect(updatedReceiverPercent).to.equal(30);
    });

    it("when receiver does not exist", async () => {
      await pledge.setReceiverPercent(receiver2.address, 20);
      const updatedReceiver2Percent = await pledge.getReceiverPercent(
        receiver2.address
      );
      console.log("updated receiver percent: ", updatedReceiver2Percent);
      expect(updatedReceiver2Percent).to.equal(20);
    });
  });
});
