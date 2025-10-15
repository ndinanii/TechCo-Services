/**
 * @description Controller for Account and Opportunity visualizations
 * @author TechCo Services
 * @date October 2025
 * Handles both Visualforce and Lightning Web Component interactions
 * Implements security best practices and efficient data retrieval
 */
public with sharing class AccountViewController {
  // Constants for pagination and error messages
  private static final Integer DEFAULT_QUERY_LIMIT = 200;
  private static final String ERROR_NO_ACCESS = 'Insufficient permissions to access records';

  /**
   * @description Inner wrapper class to combine Account data with its Opportunity count
   * Used by the Visualforce page to display account information with related opportunity counts
   */
  public class AccountWrapper {
    @AuraEnabled
    public Account acc { get; set; }
    @AuraEnabled
    public Integer oppCount { get; set; }

    public AccountWrapper(Account acc, Integer oppCount) {
      this.acc = acc;
      this.oppCount = oppCount;
    }
  }

  /**
   * @description Retrieves all accounts with their associated opportunity counts
   * Uses efficient subquery pattern and enforces field-level security
   * @return List<AccountWrapper> List of accounts with opportunity counts
   * @throws AuraHandledException if user lacks necessary permissions
   */
  public List<AccountWrapper> getAccountsWithOppCount() {
    List<AccountWrapper> accountWrappers = new List<AccountWrapper>();

    try {
      // Using a subquery in a single SOQL call is the most efficient way to get this data
      // WITH SECURITY_ENFORCED ensures user has proper field-level and object-level permissions
      for (Account acc : [
        SELECT Id, Name, Industry, (SELECT Id FROM Opportunities)
        FROM Account
        WITH SECURITY_ENFORCED
        ORDER BY Name
        LIMIT :DEFAULT_QUERY_LIMIT
      ]) {
        // Null-safe access to opportunities list
        Integer oppCount = (acc.Opportunities != null)
          ? acc.Opportunities.size()
          : 0;
        accountWrappers.add(new AccountWrapper(acc, oppCount));
      }
    } catch (Exception e) {
      // Handle security and other exceptions gracefully for VF usage
      System.debug(
        LoggingLevel.ERROR,
        'Account query exception: ' + e.getMessage()
      );
      // For Visualforce getters, avoid throwing AuraHandledException.
      // Return an empty list so the page can still render, ideally with a page message.
      return new List<AccountWrapper>();
    }

    return accountWrappers;
  }

  /**
   * @description Returns opportunity stage counts for the LWC chart
   * Uses aggregate SOQL for optimal performance
   * @AuraEnabled(cacheable=true) enables client-side caching in LWC for better performance
   * @return List<OpportunityStageCount> List of stage names with their counts
   * @throws AuraHandledException if user lacks necessary permissions
   */
  @AuraEnabled(cacheable=true)
  public static List<OpportunityStageCount> getOpportunityCountsByStage() {
    List<OpportunityStageCount> results = new List<OpportunityStageCount>();

    try {
      // Aggregate query with security enforcement
      // GROUP BY is efficient for counting records by stage
      for (AggregateResult ar : [
        SELECT StageName, COUNT(Id) total
        FROM Opportunity
        WITH SECURITY_ENFORCED
        GROUP BY StageName
        ORDER BY StageName
      ]) {
        OpportunityStageCount osc = new OpportunityStageCount();
        // Null-safe casting with validation
        osc.stage = (String) ar.get('StageName');
        osc.count = (Long) ar.get('total');

        // Only add if stage name is not null
        if (String.isNotBlank(osc.stage)) {
          results.add(osc);
        }
      }
    } catch (Exception e) {
      // Handle security exceptions gracefully for LWC consumption
      System.debug(
        LoggingLevel.ERROR,
        'Opportunity aggregate exception: ' + e.getMessage()
      );
      throw new AuraHandledException(ERROR_NO_ACCESS + ': ' + e.getMessage());
    }

    return results;
  }

  /**
   * @description Wrapper class to hold opportunity stage data for LWC visualization
   * Contains stage name and count for chart rendering
   */
  public class OpportunityStageCount {
    @AuraEnabled
    public String stage { get; set; }
    @AuraEnabled
    public Long count { get; set; }
  }
}
