/**
 * Created by Uladzislau Yarshou on 30.09.21
**/

trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
	if(Trigger.isBefore && Trigger.isInsert) {
//		ContactTriggerHandler.beforeInsert(Trigger.new);
	} else if(Trigger.isAfter && Trigger.isUpdate) {
		ContactTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
	}

	/*
	if(!ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE) {
		return;
	}

	ContactTriggerHandler.IS_ALLOW_AFTER_UPDATE = false;

	Set<Id> parentIds = new Set<Id>();
	if(!Trigger.isDelete) {
		for(Contact contact : Trigger.new) {
			parentIds.add(contact.Parent_Contact__c);
		}
	}
	if(!Trigger.isInsert && !Trigger.isUndelete) {
		for(Contact contact : trigger.old) {
			parentIds.add(contact.Parent_Contact__c);
		}
	}
	System.debug(parentIds);
	List<Contact> parentContacts = [SELECT Id, ChildCount__c, Name, (SELECT Id, Name FROM Contacts__r) FROM Contact WHERE Id IN :parentIds];
	System.debug(parentContacts);
	for(Contact contact : parentContacts) {
		System.debug(contact);
		System.debug(contact.Contacts__r.size());
		contact.ChildCount__c = contact.Contacts__r.size();
	}

	update parentContacts;

	 */
}