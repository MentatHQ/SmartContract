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
        name skillType;
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
    mapping( address => agent) agents; 
    
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
    
    function assignTaskToAgent(string _task, string _skill, uint _level) public {
        
        uint auxSkillID;
        uint auxMaxToken = 0;
        uint auxAgentID;

        // Look-up for the skill ID
        for (uint i = 0; i < skills.length-1; i++) {    
            if(skills[i].skillName == _skill) {
                auxSkillID = skills[i].ID;
                // TODO: to consider if skill not found in struct
            }
        }
        
        // Look-up for the required ID and level
        for(uint j = 0; j < agentXskills.length-1; j++) {
            if(agentXskills[j].IDskill == auxSkillID && agentXskills[j].IDskill.level == _level ) {
                if(agentXskills[j].TOKENBALANCE > auxMaxToken) {    // TODO: Implement the function to retrieve MENT balance from address
                    auxAgentID = agentXskills[j].IDagent;
                    auxMaxToken = agentXskills[j].TOKENBALANCE; // field to be changed...
            }
        }
        
        // Update Agent
        agent[auxAgentID].isBusyNow = true;
        
        // Create task
        task.push();
        task.IDcustomer = ....  // TODO
        task.skillLevelRequired = _level;
        task.dateCreated = now;
        task.ClosedDateTime = 0;
        task.description = _task;
        task.buyerAddress = ...  // TODO
        task.isClosed = false;
    }
             
    function agentTurnOnLine() public {
        // Params: address ethAddress
        // Returns
    }

    function agentTurnOffLine() public {
        // Params: address ethAddress
        // Returns:
    }

    function agentTurnBusy() public {
        // Params: address ethAddress
        // Returns:
    }

    function agentRemoval() public {
        // Params: address ethAddress
        // Returns: bool removalOK
    }

    function agentAddSkill() public {
        // Params: address ethAddress, string skill
        // Returns:
    }

    function agentRemoveSkill() public {
        // Params: address ethAddress
        // Returns:
    }

    function agentSignUp() public {
        // Params: string name, string email, address ethAddress
        // Returns: bool signUpOK
    }

    function isAgentLoggedIn() public {
        // Params: address agent
        // Returns:bool loggedIn 
    }

    function agentSignIn() public {
        // Params: address agent
        // Returns:bool loggedIn
    }

    function agentUpdateAccount() public {
        // Params: address ethAddress, string name, string email
        // Returns:
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
