pragma solidity ^0.4.23;

contract Mentat {
    
    /////
    // State variables (ledger)
    ///////////////////////////////
     
    address public owner;  // contract´s creator
    enum SkillType { Skill, Expertise }
    enum TaskStatus { Opened, Matched, Completed, Closed, Rejected }
    enum ChatMessageOwner { Agent, Buyer }
    
    struct Skill {
        bytes32 name;
        SkillType skill;
        address[] agents;
    }        
    Skill[] public skills;
    
    struct Agent {
        bytes32 name;
        bytes32 email;        
        AgentSkill[] agentSkills;
        uint isOffLineUntil; // DateTime
        uint createdAt; // DateTime
        uint lastAction; //DateTime
        bool isOffLine;
        bool isBusyNow;
    }
    mapping(address => Agent) agents; 
    
    struct AgentSkill {
        uint skillID;
        uint experiencePoints;
        uint level;
    }
    AgentSkill[] public agentSkills;
    
    struct Task {
        uint applicationID;
        address agent;
        address buyer;
        uint skillID;
        uint skillLevel;
        uint skillLevelMultiplier;
        bytes32 description;
        TaskStatus status;
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
    //Task[] public tasks;
    
    struct Application {
        bytes32 company;
    }
    Application[] public applications;
    
    ////
    // EVENTS
    ///////////////
    
    event SUCCESS(bytes32 message);
    event FAIL(bytes32 message);
    
    ////
    // Methods
    ///////////////
    
    constructor() public {
        owner = msg.sender;
    }
    
    function agentSignIn() public { 
        emit SUCCESS("signedIn"); //TODO: remove stub
        agents[msg.sender].isOffLine = false;
    }

    function agentSignUp(bytes32 name, bytes32 email) public {
        emit SUCCESS("signedUp"); //TODO: remove stub
        // Params: bytes32 name, bytes32 email, address ethAddress
        // Returns: bool signUpOK
    }

    function agentGetTask() public view returns(
        uint taskId,
        uint applicationID,
        address buyer,
        bytes32 description,
        uint status, // TaskStatus
        bool isForReview,
        address reviewAgent1,
        address reviewAgent2,
        address reviewAgent3,        
        bool reviewResult1,
        bool reviewResult2,
        bool reviewResult3,
        uint price,
        uint createdAt //DateTime*/
) {
        //Task memory task = Task(1, msg.sender, msg.sender, 1,2,1,"test description", TaskStatus.Opened, false, msg.sender, msg.sender, msg.sender, true, true, true, 100, 200, 1526480941, 1526480941, 1526480941);
        return (uint(1), uint(1), msg.sender, "test description", uint(TaskStatus.Opened), false, msg.sender, msg.sender, msg.sender, true, true, true, uint(100), uint(1526480941));
        
        // Params: address ethAddress, uint taskID
        // Returns: bool agentGotTask
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
        // Params: address ethAddress, bytes32 skill
        // Returns:
    }


    function isAgentLoggedIn(address _ethAddress) private returns (bool) {
        bool loggedIn = false;
        if (agents[_ethAddress].isOffLine == false) {
            loggedIn = true;
        }
        return loggedIn;
    }

    function agentUpdateAccount(address _ethAddress, bytes32 _name, bytes32 _email) public {
        agents[_ethAddress].name = _name;
        agents[_ethAddress].email = _email;
    }

    function agentUpdateSkillLevel() public {
        // Params: address ethAddress, bytes32 skill, uint newLevel
        // Returns:
    }

    function updateAgentExperiencePoints() public {
        // Params: address ethAddress, bytes32 skill, uint newPoint
        // Returns:
    }

    function addTask() public {
        // Params: uint applicationID, uint skillID, uint skillLevel, uint skillMultiplier, bytes32 task, uint expectedTime, uint expectedPrice
        // Returns: uint taskID
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
        // Params: uint skiillID, bytes32 newName
        // Returns:
    }
    

}
