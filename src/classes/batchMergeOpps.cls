global class batchMergeOpps implements Database.Batchable<sObject> {
	
	String query;
	
	global batchMergeOpps(String theQuery) {
		query=theQuery;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		// isolate an opp

   		Opportunity ourOpp = new Opportunity();

   		for(sObject o : scope) {
   			ourOpp = (Opportunity)o;
   		}

   		system.debug('our opp ++++ ' + ourOpp);

   		// get the opp name and Account Name (to check if it exists)

   		Id theOppId = ourOpp.Id;

   		String theOppName = ourOpp.Name;

   		String theOppNameLeft = theOppName.substringBefore('-').trim();

   		system.debug('theOppNameLeft ++++ ' + theOppNameLeft);

   		// query for an account with the opp name which is in format 'NAME - US12391'

   		List<Opportunity> badOpp  = [Select Id, StageName, CloseDate, Amount, External_Id__c, CreatedDate, Status__c, OwnerId, Name, Account.Name, AccountId FROM Opportunity WHERE Account.Name LIKE :theOppNameLeft];

   		// If there was an account, find the bad opp to get some data

   		system.debug ('badOpp ++++ ' + badOpp);

   		Id accId;

   		Opportunity dataOpp = new Opportunity();

   		if (badOpp.size() == 1) {
   			accId = badOpp[0].AccountId;
   			dataOpp = badOpp[0]; 
   		}

   		system.debug ('dataOpp ++++ ' + dataOpp);

   		Opportunity updateOpp = new Opportunity();
   		updateOpp.Id = ourOpp.Id;
   		updateOpp.AccountId = dataOpp.AccountId; // got this from badOpp query with good account
   		//updateOpp.StageName = dataOpp.StageName;
   		updateOpp.Status__c = dataOpp.Status__c;
   		updateOpp.CloseDate = dataOpp.CloseDate;
   		updateOpp.Amount = dataOpp.Amount;
   		updateOpp.External_Id__c = dataOpp.External_Id__c;
   		updateOpp.OwnerId = dataOpp.OwnerId;

   		update updateOpp;

   		system.debug ('updateOpp ++++ ' + updateOpp);

   		// move products

   		List<OpportunityLineItem> oppProds = [SELECT Id, OpportunityId, Product2.External_Id__c, Product2Id, Quantity, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :dataOpp.Id];
   		
   		List<OpportunityLineItem> insertOppProds = new List<OpportunityLineItem>();

   		for (OpportunityLineItem oli : oppProds) {
   			OpportunityLineItem newOli = new OpportunityLineItem();
   			newOli.OpportunityId = theOppId;
   			newOli.Product2Id = oli.Product2Id; 
   			newOli.Quantity = oli.Quantity;
   			newOli.TotalPrice = oli.TotalPrice;
   			//newOli.External_Id__c = oli.External_Id__c
   			insertOppProds.add(newOli);
   		}

   		delete oppProds;

   		insert insertOppProds;


   		// move notes
    	List<Task> oppTasks = [SELECT Id, WhatId FROM TASK WHERE WhatId = :dataOpp.Id];
  		
   		List<Task> updateOppTasks = new List<Task>();

   		for (Task t : oppTasks) {
   			Task newTask = new Task();
   			newTask.Id = t.Id;
   			newTask.whatId = theOppId;
   			updateOppTasks.add(newTask);
   		}  		
	
	   	update updateOppTasks;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}