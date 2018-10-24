trigger trgOpportunity on Opportunity (before insert, after update, after insert, before update) {
    system.debug ('in trigger:::');
    trgOpportunityHandler handler = new trgOpportunityHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap);
    if(trigger.isBefore) {
        if(trigger.isUpdate) {
            handler.getOppOwnerId(trigger.New, trigger.oldMap, true, false);
            
              system.debug('Update Actions');
                for(Id oppId :Trigger.newMap.keyset()){
                    system.debug('Update Actions Up'+Trigger.newMap.get(oppId));
                    if(!Test.isRunningTest())
                    if((Trigger.oldMap.get(oppId).Status__c != Trigger.newMap.get(oppId).Status__c && Trigger.newMap.get(oppId).Status__c =='Documentation Needed') && !Trigger.newMap.get(oppId).API_Called__c){
                        
                        system.debug('Update Actions Update');
                        extConsole_OpportunityDetail.docSetCreateRequest(oppId, Trigger.newMap.get(oppId).External_Id__c, Trigger.newMap.get(oppId).Notes__c);
                        
                        Trigger.newMap.get(oppId).API_Called__c = true;
                    }
               }   
            
        } else if(trigger.isInsert) {
            handler.assignStandardPriceBook(trigger.New);
            handler.getOppOwnerId(trigger.New, trigger.oldMap, false, true);
        }
    } else if(trigger.isAfter) {
        if(trigger.isUpdate) {
            //#158712198 Close Losing an Opp
            handler.closeLosingOpp(trigger.New, trigger.oldMap);

            if (checkRecursive.runOnce()) {
                handler.updateDexcomNoteTask(trigger.New, trigger.OldMap);
                handler.assignDexcomFields(trigger.New);
                handler.createADMDocs(trigger.New, trigger.oldMap);
            }
        } else if (trigger.isInsert) {
                handler.sendDexcomLeadToHub(trigger.New);
                handler.createDexcomNoteTask();
                                 
        }
    }
    
    
    
}