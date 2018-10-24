public with sharing class trgProviderHandler {
	public trgProviderHandler() {
		
	}

	public static void standardizeProviders(List<Provider__c> triggerNew) {

		// this method takes in trigger values for Provider and
		// puts them through the standardization batch job

		Set<Id> providerIds = new Set<Id>();

		for(Provider__c p : triggerNew) {
			providerIds.add(p.Id);
		}


		batchStandardizeAddress ba = new batchStandardizeAddress('', providerIds);
		if (!Test.isRunningTest()) {
			Database.executeBatch(ba, 1);
		}
		else {
			Database.executeBatch(ba, 3);
		}
		System.debug('completion of trgProviderHandler::: standardizeProviders:: ');
	}


	public static void attachLocation(List<Provider__c> triggerNew) {
		List<Location__c> locationsToInsert = new List<Location__c>();
		Map<String, Location__c> mapLocationKeyToLocation = new Map<String, Location__c>();
		Map<String, Id> mapLocationKeyToProviderId = new Map<String, Id>();
		//Create or Update Location of Provider
		for(Provider__c theProvider : triggerNew) {
			/*
            *
            * Key depends on workflow rule on the Location Object. Make sure the format matches the format in the worklfow rule
            *
            * */
			if (theProvider.Address_Verified__c == true && theProvider.Address__c != '' && theProvider.City__c != '' && theProvider.State__c != '' && theProvider.Zip__c != '' && theProvider.Address__c != null && theProvider.City__c != null && theProvider.State__c != null && theProvider.Zip__c != null) {
				String key = String.valueOf(theProvider.Address__c) + '!' + String.valueOf(theProvider.Address2__c) + '!' + String.valueOf(theProvider.City__c) + '!' + String.valueOf(theProvider.State__c) + '!' + String.valueOf(theProvider.Zip__c);
				System.debug('KEY: ' + key);
				mapLocationKeyToProviderId.put(key, theProvider.Id);
			}
		}

		Map<Id, Location__c> mapIdToLocation = new Map<Id, Location__c>([SELECT Id, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Zip_Code__c, Location_Key__c FROM Location__c WHERE Location_Key__c IN : mapLocationKeyToProviderId.keySet()]);
		for(Location__c theLocation : mapIdToLocation.values()) {
			mapLocationKeyToLocation.put(theLocation.Location_Key__c, theLocation);
		}

		for(String locationKey : mapLocationKeyToProviderId.keySet()) {
		//	Id providerId = mapLocationKeyToProviderId.get(locationKey);
			if(!mapLocationKeyToLocation.containsKey(locationKey)) {
				//Create New Location
				Location__c temporaryLocation = createLocationFromLocationKey(locationKey);
				System.debug(temporaryLocation);
				mapLocationKeyToLocation.put(locationKey, temporaryLocation);
				locationsToInsert.add(temporaryLocation);
			}
		}

		if(!locationsToInsert.isEmpty()) INSERT locationsToInsert;
	} //public static void attachLocation(List<Provider__c> triggerNew)



	private static Location__c createLocationFromLocationKey(String locationKey) {
		List<String> addressData = locationKey.split('!');
		System.debug('addressData: ' + addressData);
		Location__c theLocationToReturn = new Location__c();

		//Account for missing information
		if (addressData[0] == 'null') return null;
		else theLocationToReturn.Address_Line_1__c = addressData[0];
		if (addressData[1] == 'null') theLocationToReturn.Address_Line_2__c = '';
		else theLocationToReturn.Address_Line_2__c = addressData[1];
		if (addressData[2] == 'null') return null;
		else theLocationToReturn.City__c = addressData[2];
		if (addressData[3] == 'null') return null;
		else theLocationToReturn.State__c = addressData[3];
		if (addressData[4] == 'null') return null;
		else theLocationToReturn.Zip_Code__c = addressData[4];

		return theLocationToReturn;
	} //private static Location__c createLocationFromLocationKey(String locationKey)
}