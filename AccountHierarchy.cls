/*
    Project#-4619
    Purpose : This class is used to query and store account hierarchy data  
    
    Change History: 
    5-Oct-2015 : 1. Added Parameter "excludeId" to method getPartialNode()
    5-Oct-2015 : 2. Added additional clause to subQuery in xformAccount() method 
    7-Oct-2015 : 3. Modified xformAccount() method by removing (Id != excludeId) clause from main query
*/
global class AccountHierarchy {
    
    private static Integer recLimit = 10;
    
    /**
     * Purpose: Retrieve the account and its children - only one level deep
     *          this is a top level. This method gets called from AccountHierarchyController 
     * Arguements : Id(AccountId), AccountHierarchy(wrapper object instance to store the result), Integer(Offset), String(WhereClause)
     * Return-Type : SplsAcct(Wrapper object)
     */  
    public static SplsAcct getPartialNode(Id acctId, Id excludeId, AccountHierarchy objStore, Integer offset, String whereClause) {
        
        system.debug('--ObjStore--' + objStore);        
        SplsAcct current = objStore.xformAccount( acctId, excludeId, recLimit, offset, whereClause);        
        current.selected = true;
        
        return current;
    }    
    
    /**
     * Purpose: This method is used to build the acct hierarchy starting 
     *          from the current acctId all the way up to its parent
     * Arguements: Id(AccountId)
     * Return-Type: SplsAcct(wrapper object)
     */
    public SplsAcct getAcctHierarchy(Id acctId) {
        
        SplsAcct current = xformAccount(acctId, null, 5, 0, '');        
        current.selected = true;        
                
        if ( current.ParentId != null) {
            return( getAcctAncestors( current.ParentId, current ) );
        }
        else {
          return current;   
        }
    }   
    
    /**
     * Purpose: To recursively find all the ancestors for this account and convert it to an SplsAcct object 
     * Arguements: Id(AccountId), SplsAcct(Wrapper object to store the root and its descendants)
     * Return-Type: SplsAcct( wrapper object to store the root and its descendants)
     */
    private SplsAcct getAcctAncestors(Id acctId, SplsAcct origin) {
              
        SplsAcct ancestor = xformAccount(acctId, origin.Id, 5, 0, '' );
        ancestor.children.add( origin );
        
        if ( ancestor.parentId != null ) {
            return( getAcctAncestors( ancestor.ParentId, ancestor));
        }
        return ancestor;
    }
    
    /*
        Purpose : This method is used to transform Account records to splsAcct record with its children
        Arguements : Id(AccountId), Id(ExcludeId), Integer(RecordLimit), Integer(OffSetNumber), String(WhereClause) 
        Return Type : splsAcct
    */
    public SplsAcct xformAccount(Id acctId, Id excludeId, Integer recordLimit, Integer offsetNumber, string whereClause){
        
        SplsAcct wrapperAcct = new SplsAcct();
        
        String subQuery = '( Select Id, name, parentId, type, street_1__c, Owner.lastname,' + 
                           ' Sunrise_Status__c, Ship_To_Number__c, Bill_To_Number__c,' + 
                           ' Consortium_Number__c, MasterNumber__c, Master_Account_Division__c, Master_Account__c, Account_Key__c, Business__c, Business__r.Name,' +
                           ' City__c, State_Province__c, YTD_Net_Sales__c,YTD_Sales1__c,' + 
                           ' Last_SA_com_Sunrise_Order_Date__c, Last_Order_Date__c FROM ChildAccounts ' +
                           ' WHERE ParentId = :acctId AND' +
                           ' Id != :excludeId '+ whereClause + //Added 5-Oct-2015
                           ' ORDER BY name asc ' + 
                           ' LIMIT :iNewLimit ' +
                           ' OFFSET :offsetNumber ' +
                           ')';
        
        Integer iNewLimit = recordLimit + 1;
        List<Account> lstAcct = Database.Query('select Id, name, parentId, type, street_1__c, Owner.lastname,' + 
                                               'Sunrise_Status__c, Ship_To_Number__c, Bill_To_Number__c,' + 
                                               'City__c, State_Province__c, YTD_Net_Sales__c, YTD_Sales1__c,' + 
                                               'Consortium_Number__c, MasterNumber__c, Master_Account_Division__c, Master_Account__c, Account_Key__c, Business__c, Business__r.Name,' + 
                                               'Last_SA_com_Sunrise_Order_Date__c, Last_Order_Date__c,' +
                                                subQuery +   
                                               'FROM Account ' +
                                               'WHERE id = :acctId ' + //Removed Id != excludeId - 7-Oct-2015  
                                               ' LIMIT 1'); 
        
        if(!lstAcct.isEmpty()){
        
            wrapperAcct.id = lstAcct[0].Id;
            wrapperAcct.name = lstAcct[0].name;
            wrapperAcct.parentId = lstAcct[0].ParentId;        
            wrapperAcct.acctType = lstAcct[0].Type;
            wrapperAcct.street1  = lstAcct[0].Street_1__c;
            wrapperAcct.ownerLast = lstAcct[0].Owner.lastname;
            wrapperAcct.sunStatus = lstAcct[0].Sunrise_Status__c;
            wrapperAcct.accountNumber = lstAcct[0].Account_Key__c;
            wrapperAcct.city = lstAcct[0].City__c;
            wrapperAcct.state = lstAcct[0].State_Province__c;
            wrapperAcct.businessName = lstAcct[0].Business__r.Name;
            wrapperAcct.businessId = lstAcct[0].Business__c;
            
            if(lstAcct[0].Master_Account_Division__c != null &&
               lstAcct[0].Master_Account__c != null && 
               lstAcct[0].Ship_To_Number__c == null &&
               lstAcct[0].Bill_To_Number__c == null){
                wrapperAcct.ytdSales = lstAcct[0].YTD_Net_Sales__c != null ? '$' + String.valueOf(lstAcct[0].YTD_Net_Sales__c.intValue().format()) : '';
                wrapperAcct.lastOrder = lstAcct[0].Last_SA_com_Sunrise_Order_Date__c != null ? String.valueOf(lstAcct[0].Last_SA_com_Sunrise_Order_Date__c.format()) : '';
            }else{
                wrapperAcct.ytdSales = lstAcct[0].YTD_Sales1__c != null ? '$' + String.valueOf(lstAcct[0].YTD_Sales1__c.intValue().format()) : '';
                wrapperAcct.lastOrder = lstAcct[0].Last_Order_Date__c != null ? String.valueOf(lstAcct[0].Last_Order_Date__c.format()) : '';
            }
            wrapperAcct.consortiumNumber = lstAcct[0].Consortium_Number__c;
            wrapperAcct.masterNumber = lstAcct[0].MasterNumber__c;
            
            wrapperAcct.excludeId = excludeId;
            wrapperAcct.offSetIndex = offsetNumber;
            wrapperAcct.childLimit = recordLimit;
            wrapperAcct.childCount = 0;
            
            if(lstAcct[0].ChildAccounts != null && lstAcct[0].ChildAccounts.size() > 0){
                List<SplsAcct> lstChilds = shallowXform(lstAcct[0].childAccounts, excludeId, offsetNumber);
                wrapperAcct.childCount = lstChilds.size();
                wrapperAcct.children.addAll(lstChilds);
            }
        }
        
        return wrapperAcct;
    }
    
    /*
     * Purpose: This method is used to transform the account childs from Account object to SplsAcct records
     * Arguements: List<Account> (list of child account records), 
     *             Id(excludeId-To filter the already queried record),
     *             Integer(offset number)          
     * Return-Type: List<SplsAcct>  
     */
    private List<SplsAcct> shallowXform(List<Account> aList, Id excludeId, integer offsetNumber) {
        List<SplsAcct> splsAcctList = new List<SplsAcct>();
        for( Account a: aList ) {
            if (a.Id != excludeId) {
                SplsAcct b = new SplsAcct();
                b.id = a.Id;
                b.name = a.name;
                b.parentId = a.ParentId;
                b.acctType = a.Type;
                b.street1  = a.Street_1__c;
                b.ownerLast = a.Owner.lastname;
                b.sunStatus = a.Sunrise_Status__c;
                b.accountNumber = a.Account_Key__c;
                //b.billToNumber = a.Bill_To_Number__c;
                b.city = a.City__c;
                b.state = a.State_Province__c;
                b.businessName = a.Business__r.Name;
                b.businessId = a.Business__c;
                
                if(a.Master_Account_Division__c != null &&
                   a.Master_Account__c != null && 
                   a.Ship_To_Number__c == null &&
                   a.Bill_To_Number__c == null){
                    b.ytdSales = a.YTD_Net_Sales__c != null ? '$' + String.valueOf(a.YTD_Net_Sales__c.intValue().format()) : '';
                    b.lastOrder = a.Last_SA_com_Sunrise_Order_Date__c != null ? String.valueOf(a.Last_SA_com_Sunrise_Order_Date__c.format()) : '';
                }else{
                    b.ytdSales = a.YTD_Sales1__c != null ? '$' + String.valueOf(a.YTD_Sales1__c.intValue().format()) : '';
                    b.lastOrder = a.Last_Order_Date__c != null ? String.valueOf(a.Last_Order_Date__c.format()) : '';
                }
                
                b.offSetIndex = offsetNumber++;
                b.consortiumNumber = a.Consortium_Number__c;
                b.masterNumber = a.MasterNumber__c;
                b.childLimit = recLimit;
                b.childCount = [Select Count() FROM Account where parentId =: a.Id LIMIT 1]; //As the childs for this record is not yet queried
                
                splsAcctList.add(b);
            }
        }
        
        //need to query list in asc order since we added offSetIndex
        //page was designed to get list in desc order
        //so we reverse the list
        list<splsAcct> reverseList = new list<splsAcct>();

        for(Integer i = splsAcctList.size()-1; i>=0;i--){
            reverseList.add(splsAcctList.get(i));
        }
        
        return reverseList;
    }
    
    /**
     * Inner class to store account node and collection of its childs
     */
    global class SplsAcct {
        public String id         {get; set;}
        public String name         {get; set;}
        public String parentId       {get; set;}
        public Integer childCount     {get; set;}
        public Boolean selected      {get; set;}
        public String acctType      {get; set;}
        public String street1      {get; set;}
        public String ownerLast      {get; set;}
        public String sunStatus      {get; set;}
        public String accountNumber {get; set;}
        public String businessName {get; set;}
        public Id businessId {get; set;}
        //public String billToNumber    {get; set;}
        public String city        {get; set;}
        public String state        {get; set;}
        public String ytdSales      {get; set;}
        public String lastOrder      {get; set;}
        public Integer offSetIndex    {get; set;}
        public string excludeId {get; set;}
        
        public Integer childLimit {get; set;}
        public String consortiumNumber {get; set;}
        public String masterNumber {get; set;} 
        public List<SplsAcct> children  {get; set;}
        
        public SplsAcct() {
            children = new List<SplsAcct>();
          selected = false;    
        }
        
        /*
         * Parameterized constructor
         * To create wrapper records from account object
        */
        public SplsAcct(Account recAccount){
            
            this.id = recAccount.Id;
            this.name = recAccount.Name;
            //this.parentId = recAccount.ParentId;
            this.acctType = recAccount.Type;
            this.street1  = recAccount.Street_1__c;
            this.ownerLast = recAccount.Owner.lastname;
            this.sunStatus = recAccount.Sunrise_Status__c;
            this.accountNumber = recAccount.Account_Key__c;
            this.businessName = recAccount.Business__r.Name;
            this.businessId = recAccount.Business__c;
            //this.billToNumber = recAccount.Bill_To_Number__c;
            this.city = recAccount.City__c;
            this.state = recAccount.State_Province__c;
            
            if(recAccount.Master_Account_Division__c != null &&
               recAccount.Master_Account__c != null && 
               recAccount.Ship_To_Number__c == null &&
               recAccount.Bill_To_Number__c == null){
                this.ytdSales = recAccount.YTD_Net_Sales__c != null ? '$' + String.valueOf(recAccount.YTD_Net_Sales__c.intValue().format()) : '';
                this.lastOrder = recAccount.Last_SA_com_Sunrise_Order_Date__c != null ? String.valueOf(recAccount.Last_SA_com_Sunrise_Order_Date__c.format()) : '';
            }else{
                this.ytdSales = recAccount.YTD_Sales1__c != null ? '$' + String.valueOf(recAccount.YTD_Sales1__c.intValue().format()) : '';
                this.lastOrder = recAccount.Last_Order_Date__c != null ? String.valueOf(recAccount.Last_Order_Date__c.format()) : '';                
            }
            
            this.consortiumNumber = recAccount.Consortium_Number__c;
            this.masterNumber = recAccount.MasterNumber__c;
            this.children = new List<SplsAcct>();
        }
        
        /**
         * determine if the collection of children has less elements than its total
         * count for all children 
         */
        public Boolean hasMoreChildren() {
           if ( children.size() < childCount )  return true;
           else return false;
        }
    }
}