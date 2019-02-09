const MNFT = artifacts.require("./MNFT.sol");

module.exports = function(deployer) {
  deployer.deploy(MNFT, { gas: 6000000 });
};
