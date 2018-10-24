global class batchStandardizeAddress implements Database.Batchable<sObject>, Database.allowsCallouts {
	
	String query;
	Set<Id> providerIds = new Set<Id>();	
	
	global batchStandardizeAddress(String queryString, Set<Id> recordIds) {

		providerIds = recordIds;

		if (queryString == null || queryString == '') {
			query = 'SELECT Id, Name, Address__c, Address2__c, Address3__c, Address_Clean__c, Address2_Clean__c, Address3_Clean__c, City__c, City_Clean__c, State__c, State_Clean__c, Zip__c, Zip_Clean__c, Address_Verified__c, Message__c FROM Provider__c WHERE Id IN :providerIds';
		} else {
			query=queryString;
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Provider__c> scope) {

   		// need to standardize here

   		List<Provider__c> updateProvs = new List<Provider__c>();


   		for (Provider__c p : scope) {

   			String address1 = p.Address__c == null ? '' : p.Address__c;
   			String address2 = p.Address2__c == null ? '' : p.Address2__c;
   			String address3 = p.Address3__c == null ? '' : p.Address3__c;
   			String city = p.City__c == null ? '' : p.City__c;
   			String state = p.State__c == null ? '' : p.State__c;
   			String zip = p.Zip__c == null ? '' : p.Zip__c;

   			JSONGenerator gen = JSON.createGenerator(true);

	        gen.writeStartObject();
	        gen.writeStringField('AddressLine1', address1);
	        gen.writeStringField('AddressLine2', address2);
	        gen.writeStringField('AddressLine3', address3);
	        gen.writeStringField('City', city);
	        gen.writeStringField('State', state);
	        gen.writeStringField('ZipOrPostalCode', zip);
	        gen.writeEndObject();

        	String theJson = gen.getAsString();

        	system.debug ('provider batch JSON ::: ' + theJson);
        	system.debug ('provider ID::: ' + p.Id);

        	SolaraHubIntegration.callHubService('getStandardAddress', 'POST', theJson, p.Id);
        }
		
	}
	

	global void finish(Database.BatchableContext BC) {
		
	}
	
}