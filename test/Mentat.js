const Mentat = artifacts.require("./Mentat.sol");

contract('Mentat', (accounts) => {

    it("should get agent's task", async () => {
        const mentat = await Mentat.new();
        const task = await mentat.agentGetTask();
        console.log(task);
    });

    it("should return True if agent data was update correctly", async () => {
        const mentat = await Mentat.new("NewNameOfTheAgent","NewEmailOfTheAgent");
        const task = await mentat.agentUpdateAccount();
        console.log(task);
    });
    
});
