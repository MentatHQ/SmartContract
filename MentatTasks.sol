pragma solidity ^0.4.20;

contract MentatTasks {
        
    address public owner;  // contract´s creator
    
    struct skill {
        uint ID;
        uint customerID;
        string skillName;
        bool isExpertise; 
    }        
    skill[] public skills;
    
    struct agent {
        uint ID;
        uint isOffLineUntil; // DateTime
        uint createdAt; // DateTime
        string name;
        string homeAddress;
        string email;
        address ethAddress;
        bool isOffLine;
        bool isBusyNow;
    }
    agent[] public agents;
    
    struct agentXskill {
        uint IDagent;
        uint IDskill;
        uint experiencePoints;
        uint level;
    }
    agentXskill[] public agentXskills;
    
    struct task {
        uint ID;
        uint IDcustomer;
        uint IDSkillRequired;
        uint skillLevelRequired;
        uint dateCreated; // DateTime
        uint ClosedDateTime; // DateTime
        string description; // the task itself (question from the buyer)
        address buyerAddress;
        bool isClosed;
    }
    task[] public tasks;
    
    struct response {
        uint ID;
        uint taskID;
        uint agentID;
        uint buyerID;
        uint createdByID;
        uint createdAt; // DateTime
        string response;
    }
    response[] public responses;

    struct taskHistory {
        uint ID;
        uint taskID;
        uint marketRate;
        uint expectedCompleteTime;
        uint expectedPrice;
        uint actualTime;  // DateTime
        uint ActualPrice;
        uint skillRequiredID;
        uint skillLevelRequried;
        uint reviewerID1;
        uint reviewerID2;
        uint reviewerID3;        
        uint requestDateTime;  // DateTime
        uint acceptedDateTime;  // DateTime
        uint completedDateTime;  // DateTime
        uint reviewedDateTime;  // DateTime
        address agentAddress;
        address buyerAddress;
        bool neededOvertime;
        bool IsForReview; 
        string taskAnswer;
        string reviewResult1;
        string reviewResult2;
        string reviewResult3;
        string status; // 1 char
    }
    taskHistory[] public taskHistorys;
    
    struct buyer {
        uint ID;
        string name;
        address ethereumAddress;
    }
    buyer[] public buyers;
    
    struct agentHistory {
        uint agentID;
        uint loginDateTime; // DateTime
        uint logoutDateTime; // DateTime
    }
    agentHistory[] public agentHistorys;
    
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
    
    
    
    
    function priceCalculation(uint _expectedTime) view public {
        
    }
    
    function agentAdd() {
        
    }
    
    function agentRemove() {
        
    }
    
/*    

Other functions to be implemented:

    agentUpdate()
    agentsListing()
    agentTurnOnLine()
    agentTurnOffLine()
    agentTurnBusy()
    agentTurnAvailable()
    
    skillAdd()
    skillRemove()
    skillUpdate()

    addSkillToAgent()
    removeSkillFromAgent()
    updateExperiencePoints()
    updateAgentSkillLevel()
    
    addTask()
    closeTask()
    
    addResponse()
    
    addReviewToTask()
    
    setTaskFinalPrice()
    
    buyerAdd()
    buyerUpdate()
    buyerDelete()
    
    setAgentLogin()
    setAgentLogout()
    
    
*/

}
