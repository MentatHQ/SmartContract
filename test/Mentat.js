const Mentat = artifacts.require("./Mentat.sol");

contract('Mentat', (accounts) => {

    it("should get agent's task", async () => {
        const mentat = await Mentat.new();
        const task = await mentat.agentGetTask();
        console.log(task);
    });

});