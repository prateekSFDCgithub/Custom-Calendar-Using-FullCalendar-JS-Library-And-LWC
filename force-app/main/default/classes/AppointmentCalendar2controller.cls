public class AppointmentCalendar2controller {
@AuraEnabled(cacheable=true)
public static List<ServiceAppointment> getAllMeetingsData() {
    List<ServiceAppointment> meetingsList = [
        SELECT ID, SchedEndTime, SchedStartTime, Room_Name__c
        FROM ServiceAppointment
    ];
    
    // Define the target timezone
    TimeZone targetTimeZone = TimeZone.getTimeZone('America/New_York');

    for(ServiceAppointment meet: meetingsList) {
        if (meet.SchedEndTime != null) {
            // Convert SchedEndTime to America/New_York timezone
            meet.SchedEndTime = meet.SchedEndTime.addSeconds(
                targetTimeZone.getOffset(meet.SchedEndTime) / 1000
            );
        }
        if (meet.SchedStartTime != null) {
            // Convert SchedStartTime to America/New_York timezone
            meet.SchedStartTime = meet.SchedStartTime.addSeconds(
                targetTimeZone.getOffset(meet.SchedStartTime) / 1000
            );
        }
    }
    
    system.debug('Meeting List: ' + meetingsList);
    return meetingsList;
}

    @AuraEnabled
    public static Map<String, List<String>> getPickList(String objApi, List<String> fieldApis) {
        Map<String, List<String>> picklistValuesMap = new Map<String, List<String>>();
       
        // Get the SObjectType from the objApi string
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objApi);
       
        if (sObjectType != null) {
            // Iterate over each field API name
            for (String fieldApi : fieldApis) {
                List<String> picklistValues = new List<String>();
                Schema.DescribeFieldResult fieldResult = sObjectType.getDescribe().fields.getMap().get(fieldApi).getDescribe();
               
                // Iterate through picklist values and add them to the list
                for (Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()) {
                    picklistValues.add(pickListVal.getLabel());
                }
               
                // Add the picklist values to the map with the field API name as the key
                picklistValuesMap.put(fieldApi, picklistValues);
            }
        }
        system.debug(picklistValuesMap);
        return picklistValuesMap;
    }
    @AuraEnabled
    public static list<string> ReturnAllWorkTypeNames() {
        set<string>WorkTypeNames = new set<string>();
       list<workTypeGroup>AllWorkTypes = [select name from workTypeGroup];
       for(workTypeGroup WT:AllWorkTypes){
           WorkTypeNames.add(WT.name);
       }
       return new list<string>(WorkTypeNames);
    }
    @AuraEnabled
    public static list<string> ReturnAllPurposeNames() {
        set<string>WorkTypeNames = new set<string>();
       list<workTypeGroup>AllWorkTypes = [select AdditionalInformation from workTypeGroup];
       for(workTypeGroup WT:AllWorkTypes){
           if(WT.AdditionalInformation.contains(';')){
          list<string>WorkTypeNameListSplitted = Wt.AdditionalInformation.split(';');
           for(string WTNLS :WorkTypeNameListSplitted){
            WorkTypeNames.add(WTNLS);
           }
            }
           else{
            WorkTypeNames.add(WT.AdditionalInformation);
           
           }
           
       }
       return new list<string>(WorkTypeNames);
    }
    @AuraEnabled
    public static list<string> ReturnAllLocationNames() {
        set<string>UniqueLocationNames = new set<string>();
       list<worktypegroup>AllLocationNames = [select location__c from worktypegroup ];
       for(worktypegroup WT:AllLocationNames){
           UniqueLocationNames.add(WT.location__c);
       }
       system.debug('AllWorkTypes: '+AllLocationNames);
       return new list<string>(UniqueLocationNames);
    }
     @AuraEnabled(cacheable=true)
    public static List<ServiceAppointment> getMeetingsDataByWorkType(String workTypeName) {
        return [SELECT ID, SchedEndTime, SchedStartTime, Room_Name__c, Work_Type_Name__c
                FROM ServiceAppointment
                WHERE Work_Type_Name__c = :workTypeName];
    }
   @AuraEnabled(cacheable=true)
public static List<ServiceAppointment> getMeetingsDataByFilters(String workTypeName, String purpose, String location) {
    system.debug('purpose2: ' + purpose);
    system.debug('workTypeName: ' + workTypeName);
    system.debug('location: ' + location);

    String query = 'SELECT ID, SchedEndTime, SchedStartTime, Room_Name__c FROM ServiceAppointment';
    List<String> conditions = new List<String>();

     if (!String.isEmpty(workTypeName)) {
        conditions.add('Work_Type_Name__c LIKE :workTypeName');
        workTypeName = '%' + workTypeName + '%'; // Add wildcards for binding
    }

    if (!String.isEmpty(purpose)) {
        // Splitting comma-separated purposes and constructing individual LIKE conditions
        conditions.add('AdditionalInformation LIKE :purpose');
            purpose = '%' + purpose + '%';  // Add wildcards for binding
        
    }

    if (!String.isEmpty(location)) {
        conditions.add('Location_Name__c LIKE :location');
        location = '%' + location + '%';  // Add wildcards for binding
    }

    if (!conditions.isEmpty()) {
        query += ' WHERE ' + String.join(conditions, ' AND ');
    }

    system.debug('query: ' + query);
    List<ServiceAppointment> result = Database.query(query);
    system.debug('queryResult: ' + result);
    return result;
}
@AuraEnabled
public static list<string> returnWorkTypesAccordingToLocation(string location){
    try {
        System.debug('location: ' + location);
        String query = 'SELECT Id, Location__c, Name, AdditionalInformation FROM WorkTypeGroup';
        List<String> conditions = new List<String>();
        Set<String> workTypeNames = new Set<String>();

        if (!String.isEmpty(location)) {
            conditions.add('Location__c = :location');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        system.debug('query: ' + query);
        List<WorkTypeGroup> result = Database.query(query);

        for(WorkTypeGroup SA :result){
            workTypeNames.add(SA.name);
        }

        system.debug('queryResult: ' + result);
        system.debug('WorkTypeNames: ' + workTypeNames);
        return new list<string>(workTypeNames);
    } catch (Exception e) {
        // Log detailed error information
        System.debug('Error in returnWorkTypesAccordingToLocation: ' + e.getMessage() + ' - Line: ' + e.getLineNumber());

        // Construct a meaningful error message for JavaScript to handle
        AuraHandledException auraException = new AuraHandledException('An error occurred while fetching work types: ' + e.getMessage());
        auraException.setMessage(e.getMessage());
        throw auraException; 
    }
}
@AuraEnabled
public static list<string> returnPurposesAccordingToWorkType(string WorkType){
    try {
        System.debug('location: ' + WorkType);
        String query = 'SELECT Id, Location__c, Name, AdditionalInformation FROM WorkTypeGroup';
        List<String> conditions = new List<String>();
        Set<String> AdditionalInformationNames = new Set<String>();

        if (!String.isEmpty(WorkType)) {
            conditions.add('Name = :WorkType');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        system.debug('query: ' + query);
        List<WorkTypeGroup> result = Database.query(query);

        for(WorkTypeGroup SA :result){
            if(Sa.AdditionalInformation.contains(';')){
          list<String>PurposeList = Sa.AdditionalInformation.split(';');
          for(string PL :PurposeList){
               AdditionalInformationNames.add(Pl);
          }
            }
            else{
                AdditionalInformationNames.add(Sa.AdditionalInformation);
            }
          
        }

        system.debug('queryResult: ' + result);
        system.debug('AdditionalInformationNames: ' + AdditionalInformationNames);
        return new list<string>(AdditionalInformationNames);
    } catch (Exception e) {
        // Log detailed error information
        System.debug('Error in returnWorkTypesAccordingToLocation: ' + e.getMessage() + ' - Line: ' + e.getLineNumber());

        // Construct a meaningful error message for JavaScript to handle
        AuraHandledException auraException = new AuraHandledException('An error occurred while fetching work types: ' + e.getMessage());
        auraException.setMessage(e.getMessage());
        throw auraException; 
    }
}
}