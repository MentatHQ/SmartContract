pragma solidity ^0.4.20;

contract MentatTasks {
    
    /////
    // State variables (ledger)
    ///////////////////////////////
     
    address public owner;  // contract´s creator
    enum skillType { Skill, Expertise }
    enum taskStatus { Open, Matched, Completed, Closed, Rejected }
    enum chatMessageOwner { Agent, Buyer }
    
    struct skill {
        string name;
        skillType skill;
        address[] agents;
    }        
    skill[] public skills;
    
    struct agent {
        string name;
        string email;        
        agentSkill[] agentSkills;
        uint isOffLineUntil; // DateTime
        uint createdAt; // DateTime
        uint lastAction; //DateTime
        bool isOffLine;
        bool isBusyNow;
    }
    mapping(address => agent) agents; 
    
    struct agentSkill {
        uint skillID;
        uint experiencePoints;
        uint level;
    }
    agentSkill[] public agentSkills;
    
    struct task {
        uint applicationID;
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint skillLevelMultiplier;
        string description;
        taskStatus status;
        bool isForReview;
        address reviewAgent1;
        address reviewAgent2;
        address reviewAgent3;        
        bool reviewResult1;
        bool reviewResult2;
        bool reviewResult3;
        uint expectedPrice;
        uint price;
        uint expectedCompleteTime;
        uint completeTime;
        uint createdAt; //DateTime
    }
    task[] public tasks;
    
    struct application {
        string company;
    }
    application[] public applications;
    
    
    ////
    // Methods
    ///////////////
    
    constructor() public {
        owner = msg.sender;
    }
    
    function agentTurnOffLine(address _ethAddress) internal {
        agents[_ethAddress].isOffLine = true;
    }

    function agentTurnOnLine(address _ethAddress) internal {
        agents[_ethAddress].isOffLine = false;
    }

    function agentTurnBusy(address _ethAddress) internal {
        agents[_ethAddress].isBusyNow = true;
    }

    function agentTurnAvailable(address _ethAddress) internal {
        agents[_ethAddress].isBusyNow = false;
    }
    
    function agentRemoval(address _ethAddress) public {
        delete agents[_ethAddress];
    }

    function agentAddSkill() public {
        // Params: address ethAddress, string skill
        // Returns:
    }

    function agentRemoveSkill() public {
        // Params: address ethAddress
        // Returns:
    }

    function agentSignUp(address _ethAddress, string _name, string _email) public {
        // Params: string name, string email, address ethAddress
        // Returns: bool signUpOK
    }

    function isAgentLoggedIn(address _ethAddress) public returns (bool) {
        bool loggedIn = false;
        if (agents[_ethAddress].isOffLine == false) {
            loggedIn = true;
        }
        return loggedIn;
    }

    function agentSignIn(address _ethAddress) public {
        agents[_ethAddress].isOffLine = false;
    }

    function agentUpdateAccount(address _ethAddress, string _name, string _email) public {
        agents[_ethAddress].name = _name;
        agents[_ethAddress].email = _email;
    }

    function agentUpdateSkillLevel() public {
        // Params: address ethAddress, string skill, uint newLevel
        // Returns:
    }

    function updateAgentExperiencePoints() public {
        // Params: address ethAddress, string skill, uint newPoint
        // Returns:
    }

    function addTask() public {
        // Params: uint applicationID, uint skillID, uint skillLevel, uint skillMultiplier, string task, uint expectedTime, uint expectedPrice
        // Returns: uint taskID
    }

    function agentGetTask() public {
        // Params: address ethAddress, uint taskID
        // Returns: bool agentGotTask
    }

    function agentAcceptTask() public {

    }

    function agentCompleteTask() public {

    }

    function agentRejectTask() public {

    }

    function checkTask() public {

    }

    function changeAgentTask() public {

    }

    function taskPriceCalculation() private {
        // Params: uint taskID
        // Returns: uint price
    }

    function chooseAgentForReviewing() public {

    }

    function agentStartReview() public {
        // Params: address agent, uint taskID
        // Returns:
    }

    function agentFinishReview() public {
        // Params: address agent, uint taskID
        // Returns: bool approved
    }

    function skillRemoval() public {
        // Params: uint skiillID
        // Returns:
    }

    function skillUpdate() public {
        // Params: uint skiillID, string newName
        // Returns:
    }

}
