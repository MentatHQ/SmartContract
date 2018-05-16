const Mentat = artifacts.require("./Mentat.sol");

module.exports = function(deployer) {
  deployer.deploy(Mentat);
};