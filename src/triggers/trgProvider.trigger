trigger trgProvider on Provider__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isBefore) {
			//call your handler.before method

		} else if (Trigger.isAfter) {
			if (Trigger.isInsert) {
				System.debug('**&&()()  About to standardize the providers');
				trgProviderHandler.standardizeProviders(Trigger.new);
			}
			else if (Trigger.isUpdate){
				System.debug('provider got updated');
				trgProviderHandler.attachLocation(Trigger.new);
			}
		}
}