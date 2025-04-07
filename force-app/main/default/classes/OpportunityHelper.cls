public class OpportunityHelper {
    
    /* Another Opportunity Trigger Methods */

    public static void setType(List<Opportunity> oppList) {
        for(Opportunity opp : oppList) {
            if(opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }

    public static void insertTask(List<Opportunity> optyList){
        List<Task> tasks = new List<Task>();
        for(Opportunity opp : optyList){
            Task task = new Task();
            task.Subject = 'Call Primary Contact';
            task.WhatId = opp.Id;
            task.WhoId = opp.Primary_Contact__c;
            task.OwnerId = opp.OwnerId;
            task.ActivityDate = Date.today().addDays(3);
            tasks.add(task);
        }
        Database.insert(tasks);
    }

    

    public static void updateDescriptionFromStage(List<Opportunity> optyList, Map<Id, sObject> oldOptyMap){
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) oldOptyMap;
        for(Opportunity opp : optyList){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.StageName != null && oldOpp.StageName != opp.StageName){
                String appendString = '\nStage Change:' + opp.StageName + ':' + DateTime.now().format();
                opp.Description = (opp.Description == null) ? appendString : opp.Description + appendString; 
            }
        }
    }
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> oldOptyList){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : oldOptyList){
            accountIds.add(opp.AccountId);
        }

        List<Opportunity> opportunities = [SELECT Id, OwnerId, Owner.email, Name FROM Opportunity Where Id IN :accountIds];
        for(Opportunity opty : opportunities){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {opty.Owner.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opty.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opty.Name +' has been deleted.');
            mails.add(mail);
        }
        try{
            Messaging.sendEmail(mails);
        }catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public static void assignPrimaryContactVpSales(Map<Id, sObject> newOptyMap){
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Opportunity> newMap = (Map<Id, Opportunity>) newOptyMap;
        for(Opportunity opp : newMap.values()){
            accountIds.add(opp.AccountId);
        }

        Map<Id, Contact> contactsByAccount = new Map<Id, Contact>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name, AccountId, Title 
                                                            FROM Contact
                                                            WHERE Title LIKE 'VP Sales' AND Contact.AccountId IN :accountIds]);

        for(Contact accountContact : contactMap.values()){
            contactsByAccount.put(accountContact.AccountId, accountContact);
        }
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        for (Opportunity opp : newMap.values()){
            if (opp.Primary_Contact__c == null){
                Contact newPrimary = contactsByAccount.get(opp.AccountId);
                Opportunity opportunityToUpdate = new Opportunity(Id = opp.Id);
                opportunityToUpdate.Primary_Contact__C = newPrimary.Id;
                opportunityMap.put(opportunityToUpdate.Id, opportunityToUpdate);
            }
        }        
        update opportunityMap.values();
                                                    
    }
    /* Opportunity Trigger Methods */

    public static void amountValidation(List<Opportunity> newOptyList){
        for(Opportunity opp: newOptyList){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }

    public static void deleteCloseWonOpportunity(List<Opportunity> oldOptyList){
        set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : oldOptyList){
            if(opp.AccountId != null && opp.StageName == 'Closed Won'){
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Account> accountToIdMap = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN :accountIds]);
        
        for(Opportunity opp : oldOptyList){
            if(opp.StageName == 'Closed Won' && accountToIdMap.get(opp.AccountId)?.Industry == 'Banking'){
                opp.addError('Cannot delete closed opportunity for a banking account that is won');
            } else if(opp.isClosed){
                opp.addError('Cannot delete closed opportunity');
            }
        }
    }

    public static void assignPrimaryContact(List<Opportunity> optyList, Map<Id, sObject> oldOptyMap){
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : optyList){
            if(opp.AccountId != null && opp.Primary_Contact__c == null){
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Contact> ceoContacts = new Map<Id, Contact>();
        List<Contact> contactList = [SELECT Id, AccountId FROM Contact Where AccountId IN :accountIds AND Title='CEO' ORDER BY FirstName ASC];
        for(Contact con : contactList){
            if(!ceoContacts.containsKey(con.AccountId)){
                ceoContacts.put(con.AccountId, con);
            }
        } 
        for(Opportunity opp : optyList){
            if(opp.AccountId != null && opp.Primary_Contact__c == null && ceoContacts.containsKey(opp.AccountId)){
                opp.Primary_Contact__c = ceoContacts.get(opp.AccountId).Id;
            }
        }

    }
}