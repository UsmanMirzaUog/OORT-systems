@isTest
private class batchMergeOpps_TEST
{
	public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Record created successfully!');
            res.setStatusCode(200);
            return res;
        }
    }

    @testsetup static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.createAllCustomSettings();
    }
	@isTest
	static void testMoveOpp()
	{
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		User u = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Clayton',
	    LastName = 'Boss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u;

		User u2 = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Blay',
	    LastName = 'Coss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u2;

		// create opp that has sharing rights with an orphaned AccountId field

		Opportunity o = new Opportunity();
		o.StageName = 'New Opportunity';
		o.CloseDate = System.Today() + 10;
		o.Name = 'CLAY BOSS - US0123456';
		o.Dexcom_Opp_Id__c = '00000';
		o.OwnerId = u.Id;

		insert o;

		// create Acc + Opp shared from ILMS but is a duplicate that needs moved

		Account a = new Account();
		a.Name = 'CLAY BOSS';

		insert a;

		Opportunity o2 = new Opportunity();
		o2.StageName = 'Prospecting';
		o2.Status__c = 'Test Status';
		o2.CloseDate = System.Today();
		o2.Name = 'Sales Order 654321: Boss, Clay';
		o2.AccountId = a.Id;
		o2.Amount = 10000;
		o2.External_Id__c = '666666';
		o2.OwnerId = u2.Id;

		insert o2;

		Test.startTest();
		String query = '';
		query = 'SELECT Id, Name, OwnerId, StageName, CreatedDate, AccountId, CloseDate, Status__c, Amount, External_Id__c FROM Opportunity ORDER BY CreatedDate ASC LIMIT 1';
		batchMergeOpps bmo = new batchMergeOpps(query);
		Database.executeBatch(bmo);
		Test.stopTest();

		Opportunity checkOpp = [SELECT Id, StageName, Status__c, CloseDate, Amount, OwnerId, External_Id__c, AccountId FROM Opportunity WHERE Id = :o.Id LIMIT 1];

		// check to make sure the data moved as expected

		system.assertEquals(checkOpp.External_Id__c, '666666');
		system.assertEquals(checkOpp.AccountId, a.Id);
//		system.assertEquals(checkOpp.StageName, 'Prospecting');
		system.assertEquals(checkOpp.Status__c, 'Test Status');
		system.assertEquals(checkOpp.CloseDate, system.Today());
		system.assertEquals(checkOpp.Amount, 10000);
		system.assertEquals(checkOpp.OwnerId, u2.Id);		

	}

	@isTest
	static void testMoveOppWithProducts()
	{
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		User u = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Clayton',
	    LastName = 'Boss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u;

		User u2 = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Blay',
	    LastName = 'Coss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u2;

		// create opp that has sharing rights with an orphaned AccountId field

		Opportunity o = new Opportunity();
		o.StageName = 'New Opportunity';
		o.CloseDate = System.Today() + 10;
		o.Name = 'CLAY BOSS - US0123456';
		o.Dexcom_Opp_Id__c = '00000';
		o.OwnerId = u.Id;

		insert o;

		// create Acc + Opp shared from ILMS but is a duplicate that needs moved

		Account a = new Account();
		a.Name = 'CLAY BOSS';

		insert a;

		Opportunity o2 = new Opportunity();
		o2.StageName = 'Prospecting';
		o2.Status__c = 'Test Status';
		o2.CloseDate = System.Today();
		o2.Name = 'Sales Order 654321: Boss, Clay';
		o2.AccountId = a.Id;
		o2.Amount = 10000;
		o2.External_Id__c = '666666';
		o2.OwnerId = u2.Id;

		insert o2;

      	Id pricebookId = Test.getStandardPricebookId();

        List<Product2> productList = new List<Product2>();
        productList.add(new Product2(Name = 'Product1', ProductCode = '1', isActive = true));
        productList.add(new Product2(Name = 'Product2', ProductCode = '2', isActive = true));
        productList.add(new Product2(Name = 'Product3', ProductCode = '3', isActive = true));

        INSERT productList;

        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));

        INSERT pbEntry;

        List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
        lineItemList.add(new OpportunityLineItem(OpportunityId = o2.Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, TotalPrice = pbEntry.get(0).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = o2.Id, Quantity = 2, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));

        INSERT lineItemList;

		Test.startTest();
		String query = '';
		query = 'SELECT Id, Name, OwnerId, StageName, CreatedDate, AccountId, CloseDate, Status__c, Amount, External_Id__c FROM Opportunity ORDER BY CreatedDate ASC LIMIT 1';
		batchMergeOpps bmo = new batchMergeOpps(query);
		Database.executeBatch(bmo);
		Test.stopTest();

		Opportunity checkOpp = [SELECT Id, StageName, Status__c, CloseDate, Amount, OwnerId, External_Id__c, AccountId FROM Opportunity WHERE Id = :o.Id LIMIT 1];

		// check to make sure the data moved as expected

		system.assertEquals(checkOpp.External_Id__c, '666666');
		system.assertEquals(checkOpp.AccountId, a.Id);
		//system.assertEquals(checkOpp.StageName, 'Prospecting');
		system.assertEquals(checkOpp.Status__c, 'Test Status');
		system.assertEquals(checkOpp.CloseDate, system.Today());
		system.assertEquals(checkOpp.Amount, 250);
		system.assertEquals(checkOpp.OwnerId, u2.Id);

		List<OpportunityLineItem> olis = [SELECT OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :checkOpp.Id];

		system.assertEquals(olis.size(), 2);		

	}
	@isTest
	static void testMoveOppWithProductsAndTasks()
	{
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		User u = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Clayton',
	    LastName = 'Boss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u;

		User u2 = new User(
	    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
	    FirstName = 'Blay',
	    LastName = 'Coss',
	    Email = 'puser000@amamama.com',
	    Username = 'puser000@amamama.com' + System.currentTimeMillis(),
	    CompanyName = 'TEST',
	    Title = 'title',
	    Alias = 'alias',
	    TimeZoneSidKey = 'America/Los_Angeles',
	    EmailEncodingKey = 'UTF-8',
	    LanguageLocaleKey = 'en_US',
	    LocaleSidKey = 'en_US'
	    //UserRoleId = r.Id
		);

		insert u2;

		// create opp that has sharing rights with an orphaned AccountId field

		Opportunity o = new Opportunity();
		o.StageName = 'New Opportunity';
		o.CloseDate = System.Today() + 10;
		o.Name = 'CLAY BOSS - US0123456';
		o.Dexcom_Opp_Id__c = '00000';
		o.OwnerId = u.Id;

		insert o;

		// create Acc + Opp shared from ILMS but is a duplicate that needs moved

		Account a = new Account();
		a.Name = 'CLAY BOSS';

		insert a;

		Opportunity o2 = new Opportunity();
		o2.StageName = 'Prospecting';
		o2.Status__c = 'Test Status';
		o2.CloseDate = System.Today();
		o2.Name = 'Sales Order 654321: Boss, Clay';
		o2.AccountId = a.Id;
		o2.Amount = 10000;
		o2.External_Id__c = '666666';
		o2.OwnerId = u2.Id;

		insert o2;

      	Id pricebookId = Test.getStandardPricebookId();

        List<Product2> productList = new List<Product2>();
        productList.add(new Product2(Name = 'Product1', ProductCode = '1', isActive = true));
        productList.add(new Product2(Name = 'Product2', ProductCode = '2', isActive = true));
        productList.add(new Product2(Name = 'Product3', ProductCode = '3', isActive = true));

        INSERT productList;

        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));

        INSERT pbEntry;

        List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
        lineItemList.add(new OpportunityLineItem(OpportunityId = o2.Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, TotalPrice = pbEntry.get(0).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = o2.Id, Quantity = 2, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));

        INSERT lineItemList;

        List<Task> taskList = new List<Task>();
        taskList.add(new Task(Subject = 'Test', Status = 'Open', Description = 'Test', WhatId = o2.Id));
        taskList.add(new Task(Subject = 'Test 2', Status = 'Completed', Description = 'Test 2', WhatId = o2.Id));

        INSERT taskList;

		Test.startTest();
		String query = '';
		query = 'SELECT Id, Name, OwnerId, StageName, CreatedDate, AccountId, CloseDate, Status__c, Amount, External_Id__c FROM Opportunity ORDER BY CreatedDate ASC LIMIT 1';
		batchMergeOpps bmo = new batchMergeOpps(query);
		Database.executeBatch(bmo);
		Test.stopTest();

		Opportunity checkOpp = [SELECT Id, StageName, Status__c, CloseDate, Amount, OwnerId, External_Id__c, AccountId FROM Opportunity WHERE Id = :o.Id LIMIT 1];

		// check to make sure the data moved as expected

		system.assertEquals(checkOpp.External_Id__c, '666666');
		system.assertEquals(checkOpp.AccountId, a.Id);
		//system.assertEquals(checkOpp.StageName, 'Prospecting');
		system.assertEquals(checkOpp.Status__c, 'Test Status');
		system.assertEquals(checkOpp.CloseDate, system.Today());
		system.assertEquals(checkOpp.Amount, 250);
		system.assertEquals(checkOpp.OwnerId, u2.Id);

		List<OpportunityLineItem> olisRightOpp = [SELECT OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :checkOpp.Id];
		List<OpportunityLineItem> olisWrongOpp = [SELECT OpportunityId FROM OpportunityLineItem WHERE OpportunityId != :checkOpp.Id];

		system.assertEquals(olisRightOpp.size(), 2);
		system.assertEquals(olisWrongOpp.size(), 0);

		List<Task> tsksRightOpp = [SELECT Id FROM TASK Where WhatId = :o.Id];
		List<Task> tsksWrongOpp = [SELECT Id FROM TASK Where WhatId = :o2.Id];
		system.assertEquals(tsksRightOpp.size(), 2);
		system.assertEquals(tsksWrongOpp.size(), 0);

	}
}