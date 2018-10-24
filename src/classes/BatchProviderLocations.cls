/**
 * Created by krizia on 6/27/18.
 */

global class BatchProviderLocations implements Database.Batchable<sObject>, Database.allowsCallouts {

    String query;
    Set<Id> providerIds = new Set<Id>();

    global BatchProviderLocations() {

        query = 'SELECT Id, Name, Address__c, Address2__c, Address3__c, Address_Clean__c, Address2_Clean__c, Address3_Clean__c, City__c, City_Clean__c, State__c, State_Clean__c, Zip__c, Zip_Clean__c, Address_Verified__c, Message__c FROM Provider__c WHERE Address_Verified__c = true ';

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Provider__c> scope) {
        System.debug('provider list size: ' + scope.size());
        trgProviderHandler.attachLocation(scope);
    }

    global void finish(Database.BatchableContext BC) {
    }

}

/*


List<Provider__c> providers2 = [SELECT Id, Name, Address__c, Address2__c, Address3__c, Address_Clean__c, Address2_Clean__c, Address3_Clean__c, City__c, City_Clean__c, State__c, State_Clean__c, Zip__c, Zip_Clean__c, Address_Verified__c, Message__c FROM Provider__c WHERE Address_Verified__c = true AND Id NOT IN :theIds LIMIT 8000];
for (Provider__c p : providers2){
    theIds.add(p.Id);
}
System.debug('provider list size 2: ' + providers2.size());
trgProviderHandler.attachLocation(providers2);

List<Provider__c> providers3 = [SELECT Id, Name, Address__c, Address2__c, Address3__c, Address_Clean__c, Address2_Clean__c, Address3_Clean__c, City__c, City_Clean__c, State__c, State_Clean__c, Zip__c, Zip_Clean__c, Address_Verified__c, Message__c FROM Provider__c WHERE Address_Verified__c = true AND Id NOT IN :theIds LIMIT 8000];
for (Provider__c p : providers3){
    theIds.add(p.Id);
}
System.debug('provider list size 3: ' + providers3.size());
trgProviderHandler.attachLocation(providers3);
 */