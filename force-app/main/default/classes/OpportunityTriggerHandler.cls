public class OpportunityTriggerHandler extends TriggerHandler{
    
    public override void beforeInsert() {
        OpportunityHelper.setType(Trigger.new);
    }

    public override void beforeUpdate() {
        OpportunityHelper.amountValidation(Trigger.new);
        OpportunityHelper.assignPrimaryContact(Trigger.new, Trigger.oldMap);
        OpportunityHelper.updateDescriptionFromStage(Trigger.new, Trigger.oldMap);

    }

    public override void beforeDelete(){
        OpportunityHelper.deleteCloseWonOpportunity(Trigger.old);
    }

    public override void afterInsert() {
        OpportunityHelper.insertTask(Trigger.new);
    }

    public override void afterDelete(){
        OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
    }

    public override void afterUndelete(){
        OpportunityHelper.assignPrimaryContactVpSales(Trigger.newMap);
    }
}